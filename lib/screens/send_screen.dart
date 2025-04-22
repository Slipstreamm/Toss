import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../models/transfer_models.dart';
import '../services/crypto_service.dart';
import '../services/hash_service.dart';
import '../services/theme_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key, required this.onStatusUpdate});

  final Function(String) onStatusUpdate;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> with WidgetsBindingObserver {
  // List of items to send
  final List<TransferItem> _itemsToSend = [];

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _textInputController = TextEditingController();
  Socket? _clientSocket;
  String? _ipError;

  // Service for calculating SHA256 hashes
  final HashService _hashService = HashService();

  // Service for encryption/decryption
  final CryptoService _cryptoService = CryptoService();

  // Flag to track if the widget is mounted
  bool _isMounted = true;

  // Flag to track if a transfer is in progress
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _cleanupResources();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    _ipController.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  // Clean up all resources
  void _cleanupResources() {
    if (_clientSocket != null) {
      _clientSocket?.destroy();
      _clientSocket = null;
    }
  }

  // Method to pick files using file picker
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

      // Check if still mounted before updating state
      if (!_isMounted) return;

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            _itemsToSend.add(TransferItem.fromPlatformFile(file));
          }
        });
        widget.onStatusUpdate('${result.files.length} file(s) selected');
      } else {
        // User canceled the picker
        widget.onStatusUpdate('File selection cancelled.');
      }
    } catch (e) {
      if (_isMounted) {
        widget.onStatusUpdate('Error picking file: $e');
      }
    }
  }

  // Method to pick an image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      // Check if still mounted before updating state
      if (!_isMounted) return;

      if (image != null) {
        // Create a PlatformFile from the XFile to maintain compatibility
        final File imageFile = File(image.path);
        final String fileName = path.basename(image.path);
        final int fileSize = await imageFile.length();

        final platformFile = PlatformFile(
          path: image.path,
          name: fileName,
          size: fileSize,
          bytes: null, // We don't need the bytes here
        );

        setState(() {
          _itemsToSend.add(TransferItem.fromPlatformFile(platformFile));
        });
        widget.onStatusUpdate('Image selected: $fileName');
      } else {
        // User canceled the picker
        widget.onStatusUpdate('Image selection cancelled.');
      }
    } catch (e) {
      if (_isMounted) {
        widget.onStatusUpdate('Error picking image: $e');
      }
    }
  }

  // Show file source selection menu
  void _showFileSourceMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: const Text('File Picker'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Text Input'),
                onTap: () {
                  Navigator.pop(context);
                  _showTextInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show text input dialog
  Future<void> _showTextInputDialog() async {
    _textInputController.clear(); // Clear previous text

    // Double-check that we're still mounted before showing dialog
    if (!_isMounted) return;

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Text to Send'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _textInputController,
                  decoration: const InputDecoration(hintText: 'Type or paste text here', border: OutlineInputBorder()),
                  maxLines: 5,
                  minLines: 3,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste from Clipboard'),
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData?.text != null) {
                      _textInputController.text = clipboardData!.text!;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, _textInputController.text), child: const Text('OK')),
            ],
          ),
    );

    if (result != null && result.isNotEmpty && _isMounted) {
      setState(() {
        _itemsToSend.add(TransferItem.fromText(result));
      });
      widget.onStatusUpdate('Text prepared for sending: ${result.length} characters');
    }
  }

  // Show confirmation dialog before sending content
  Future<bool> _showSendConfirmationDialog(List<TransferItem> items, String targetIp) async {
    // Double-check that we're still mounted before showing dialog
    if (!_isMounted) return false;

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Send'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send ${items.length} item(s):'),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length > 5 ? 5 : items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              item.type == TransferItemType.file ? 'File: ${_formatFileSize(item.size)}' : 'Text: ${_formatFileSize(item.size)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    if (items.length > 5) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('...and ${items.length - 5} more')),
                    const SizedBox(height: 8),
                    Text('To: $targetIp', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
                ],
              ),
        ) ??
        false; // Default to false if dialog is dismissed
  }

  // Validate IP address format
  bool _validateIpAddress(String ip) {
    // Simple regex for IPv4 address validation
    final ipRegex = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    return ipRegex.hasMatch(ip);
  }

  // Format file size to human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Calculate SHA256 hashes for all items in a batch
  Future<List<TransferItem>> _calculateHashes(List<TransferItem> items) async {
    final List<TransferItem> itemsWithHashes = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      String hash;

      if (item.type == TransferItemType.file && item.path != null) {
        // For files, calculate hash from the file path
        hash = await _hashService.calculateFileHash(item.path!);
        widget.onStatusUpdate('Calculated hash for ${item.name}');
      } else if (item.type == TransferItemType.file && item.bytes != null) {
        // For files with bytes already loaded
        hash = _hashService.calculateBytesHash(item.bytes!);
        widget.onStatusUpdate('Calculated hash for ${item.name}');
      } else if (item.type == TransferItemType.text && item.textContent != null) {
        // For text content
        hash = _hashService.calculateStringHash(item.textContent!);
        widget.onStatusUpdate('Calculated hash for text message');
      } else {
        // Skip items that can't be hashed
        itemsWithHashes.add(item);
        continue;
      }

      // Create a new item with the hash
      itemsWithHashes.add(
        TransferItem(
          id: item.id,
          type: item.type,
          name: item.name,
          path: item.path,
          size: item.size,
          bytes: item.bytes,
          textContent: item.textContent,
          hash: hash,
          isSelected: item.isSelected,
        ),
      );
    }

    return itemsWithHashes;
  }

  // Remove an item from the list
  void _removeItem(String id) {
    setState(() {
      _itemsToSend.removeWhere((item) => item.id == id);
    });
    widget.onStatusUpdate('Item removed');
  }

  // Clear all items
  void _clearItems() {
    setState(() {
      _itemsToSend.clear();
    });
    widget.onStatusUpdate('All items cleared');
  }

  Future<void> _sendFile() async {
    if (_itemsToSend.isEmpty) {
      widget.onStatusUpdate('Please select at least one file or enter text first.');
      return;
    }

    // Get only selected items
    final selectedItems = _itemsToSend.where((item) => item.isSelected).toList();

    if (selectedItems.isEmpty) {
      widget.onStatusUpdate('Please select at least one item to send.');
      return;
    }

    final ipAddress = _ipController.text.trim().split(':')[0]; // Remove port if included

    if (ipAddress.isEmpty) {
      widget.onStatusUpdate('Please enter the target IP address.');
      if (_isMounted) {
        setState(() {
          _ipError = 'IP address is required';
        });
      }
      return;
    }

    if (!_validateIpAddress(ipAddress)) {
      widget.onStatusUpdate('Invalid IP address format. Please use format: 192.168.1.100');
      if (_isMounted) {
        setState(() {
          _ipError = 'Invalid IP format';
        });
      }
      return;
    }

    // Clear any previous error
    if (_isMounted) {
      setState(() {
        _ipError = null;
      });
    }

    // Check if widget is still mounted before accessing context
    if (!_isMounted) return;

    final themeService = Provider.of<ThemeService>(context, listen: false);
    final clientPort = themeService.settings.clientPort;

    // Generate a unique batch ID that will be used for both hash and data transfers
    final batchId = DateTime.now().millisecondsSinceEpoch.toString();

    // Check if confirmation is required
    if (themeService.settings.confirmBeforeSending) {
      // Check if widget is still mounted before showing dialog
      if (!_isMounted) return;

      final confirmed = await _showSendConfirmationDialog(selectedItems, ipAddress);
      if (!confirmed) {
        if (_isMounted) {
          widget.onStatusUpdate('Transfer cancelled.');
        }
        return;
      }
    }

    // Check if widget is still mounted before continuing
    if (!_isMounted) return;

    // Set transfer in progress
    setState(() {
      _isTransferring = true;
    });

    widget.onStatusUpdate('Calculating SHA256 hashes for all items...');

    // Calculate hashes for all items
    final itemsWithHashes = await _calculateHashes(selectedItems);

    // Create a hash-only batch to send first
    final hashOnlyItems =
        itemsWithHashes.map((item) => TransferItem(id: item.id, type: item.type, name: item.name, size: item.size, hash: item.hash, isSelected: true)).toList();

    final hashBatch = TransferBatch.hashOnly(batchId, hashOnlyItems);

    // Convert hash batch to JSON
    final hashPayload = jsonEncode(hashBatch.toJson());

    widget.onStatusUpdate('Connecting to $ipAddress:$clientPort...');

    try {
      // First connection to send hashes
      widget.onStatusUpdate('Sending hash information...');
      _clientSocket = await Socket.connect(ipAddress, clientPort, timeout: const Duration(seconds: 5));

      // Check if widget is still mounted before updating status
      if (!_isMounted) {
        _cleanupResources();
        return;
      }

      // Send hash data
      _clientSocket!.write(hashPayload);
      await _clientSocket!.flush(); // Ensure data is sent
      _clientSocket!.close(); // Close connection after sending
      _clientSocket = null;

      widget.onStatusUpdate('Hash information sent. Preparing to send actual data...');

      // Wait a moment to ensure the receiver has processed the hash information
      await Future.delayed(const Duration(milliseconds: 500));

      // Second connection to send actual data
      _clientSocket = await Socket.connect(ipAddress, clientPort, timeout: const Duration(seconds: 5));

      // Check if widget is still mounted before updating status
      if (!_isMounted) {
        _cleanupResources();
        return;
      }

      widget.onStatusUpdate('Connected to $ipAddress:$clientPort. Sending ${selectedItems.length} item(s)...');

      // Load file data for all file items
      for (int i = 0; i < itemsWithHashes.length; i++) {
        final item = itemsWithHashes[i];

        if (item.type == TransferItemType.file && item.path != null && item.bytes == null) {
          // Load file bytes
          final fileBytes = await File(item.path!).readAsBytes();
          // Update the item with the bytes
          itemsWithHashes[i] = TransferItem(
            id: item.id,
            type: item.type,
            name: item.name,
            path: item.path,
            size: item.size,
            bytes: fileBytes,
            hash: item.hash,
            isSelected: item.isSelected,
          );
        }
      }

      // Check if encryption is enabled
      final bool useEncryption = themeService.settings.enableEncryption;
      String dataPayload;

      if (useEncryption) {
        widget.onStatusUpdate('Encrypting data with AES-256...');

        // Prepare the batch with loaded data
        final dataBatch = TransferBatch(id: batchId, items: itemsWithHashes);

        // Convert batch to JSON
        final batchJson = jsonEncode(dataBatch.toJson());

        // Encrypt the batch data
        final encryptedData = await _cryptoService.encrypt(batchJson, themeService.settings.encryptionPin);

        // Create an encrypted batch
        final encryptedBatch = TransferBatch.encrypted(batchId, encryptedData);

        // Convert encrypted batch to JSON
        dataPayload = jsonEncode(encryptedBatch.toJson());

        widget.onStatusUpdate('Data encrypted successfully.');
      } else {
        // Prepare the batch with loaded data (unencrypted)
        final dataBatch = TransferBatch(id: batchId, items: itemsWithHashes);

        // Convert batch to JSON
        dataPayload = jsonEncode(dataBatch.toJson());
      }

      // Check if still mounted before continuing
      if (!_isMounted) {
        _cleanupResources();
        return;
      }

      // Send data
      _clientSocket!.write(dataPayload);
      await _clientSocket!.flush(); // Ensure data is sent
      _clientSocket!.close(); // Close connection after sending

      // Check if widget is still mounted before updating status
      if (_isMounted) {
        final encryptionStatus = useEncryption ? ' (AES-256 encrypted)' : '';
        widget.onStatusUpdate('Successfully sent ${selectedItems.length} item(s) to $ipAddress with SHA256 verification$encryptionStatus.');

        // Optionally clear items after sending
        // setState(() {
        //   _itemsToSend.clear();
        // });
      }
    } catch (e) {
      if (_isMounted) {
        widget.onStatusUpdate('Error sending file: $e');
      }
      _cleanupResources(); // Ensure socket is closed on error
    } finally {
      _clientSocket = null; // Reset client socket

      // Reset transfer state
      if (_isMounted) {
        setState(() {
          _isTransferring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of text fields
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Send Content', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Add Content'),
                        onPressed: _isTransferring ? null : _showFileSourceMenu,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                      ),
                    ),
                    if (_itemsToSend.isNotEmpty)
                      IconButton(icon: const Icon(Icons.clear_all), tooltip: 'Clear all items', onPressed: _isTransferring ? null : _clearItems),
                  ],
                ),

                if (_itemsToSend.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Text('Selected Items (${_itemsToSend.length}):', style: const TextStyle(fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _itemsToSend.length,
                            itemBuilder: (context, index) {
                              final item = _itemsToSend[index];
                              return ListTile(
                                dense: true,
                                title: Text(item.name, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  item.type == TransferItemType.file ? 'File: ${_formatFileSize(item.size)}' : 'Text: ${_formatFileSize(item.size)}',
                                ),
                                leading: Checkbox(
                                  value: item.isSelected,
                                  onChanged:
                                      _isTransferring
                                          ? null
                                          : (value) {
                                            setState(() {
                                              _itemsToSend[index] = TransferItem(
                                                id: item.id,
                                                type: item.type,
                                                name: item.name,
                                                path: item.path,
                                                size: item.size,
                                                textContent: item.textContent,
                                                isSelected: value ?? true,
                                              );
                                            });
                                          },
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: _isTransferring ? null : () => _removeItem(item.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'Enter Target IP Address (without port)',
                    hintText: 'e.g., 192.168.1.100',
                    helperText: 'Enter only the IP address - port is configured in settings',
                    border: const OutlineInputBorder(),
                    errorText: _ipError,
                  ),
                  keyboardType: TextInputType.text, // Suggest text keyboard
                  onChanged: (value) {
                    // Update state to re-evaluate button enabled state
                    setState(() {
                      // Clear error when user types
                      if (_ipError != null) {
                        _ipError = null;
                      }
                      // No need to do anything else, just triggering setState
                      // will cause the build method to re-evaluate the button's onPressed
                    });
                  },
                ),

                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    onPressed:
                        (_itemsToSend.isEmpty || _ipController.text.isEmpty || _isTransferring)
                            ? null // Disable if no content, IP is empty, or transfer in progress
                            : _sendFile,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
