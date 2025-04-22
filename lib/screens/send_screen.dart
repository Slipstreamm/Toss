import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../services/theme_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key, required this.onStatusUpdate});

  final Function(String) onStatusUpdate;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> with WidgetsBindingObserver {
  PlatformFile? _selectedFile;
  String? _textToSend;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _textInputController = TextEditingController();
  Socket? _clientSocket;
  String? _ipError;

  // Flag to track if the widget is mounted
  bool _isMounted = true;

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

  // Method to pick a file using file picker
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      // Check if still mounted before updating state
      if (!_isMounted) return;

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
        widget.onStatusUpdate('File selected: ${_selectedFile!.name}');
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
          _selectedFile = platformFile;
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
        _textToSend = result;
        _selectedFile = null; // Clear any selected file
      });
      widget.onStatusUpdate('Text prepared for sending: ${result.length} characters');
    }
  }

  // Show confirmation dialog before sending file
  Future<bool> _showSendConfirmationDialog(String contentName, String targetIp, bool isText) async {
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
                    Text('Send ${isText ? 'text' : 'file'}: $contentName'),
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

  Future<void> _sendFile() async {
    if (_selectedFile == null && _textToSend == null) {
      widget.onStatusUpdate('Please select a file or enter text first.');
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

    final bool isTextMode = _textToSend != null;
    final String contentName = isTextMode ? 'Text message' : path.basename(_selectedFile!.path!);

    // Check if confirmation is required
    if (themeService.settings.confirmBeforeSending) {
      // Check if widget is still mounted before showing dialog
      if (!_isMounted) return;

      final confirmed = await _showSendConfirmationDialog(contentName, ipAddress, isTextMode);
      if (!confirmed) {
        if (_isMounted) {
          widget.onStatusUpdate('${isTextMode ? 'Text' : 'File'} sending cancelled.');
        }
        return;
      }
    }

    // Check if widget is still mounted before continuing
    if (!_isMounted) return;

    widget.onStatusUpdate('Connecting to $ipAddress:$clientPort...');

    try {
      _clientSocket = await Socket.connect(ipAddress, clientPort, timeout: const Duration(seconds: 5));

      // Check if widget is still mounted before updating status
      if (!_isMounted) {
        _cleanupResources();
        return;
      }

      widget.onStatusUpdate('Connected to $ipAddress:$clientPort. Sending ${isTextMode ? 'text' : 'file'}...');

      // Prepare JSON payload based on content type
      String payload;

      if (isTextMode) {
        // For text data
        payload = jsonEncode({'type': 'text', 'data': _textToSend});
      } else {
        // For file data
        final fileBytes = await File(_selectedFile!.path!).readAsBytes();
        final fileContentBase64 = base64Encode(fileBytes);

        payload = jsonEncode({'type': 'file', 'filename': contentName, 'data': fileContentBase64});
      }

      // Check if still mounted before continuing
      if (!_isMounted) {
        _cleanupResources();
        return;
      }

      // Send data
      _clientSocket!.write(payload);
      await _clientSocket!.flush(); // Ensure data is sent
      _clientSocket!.close(); // Close connection after sending

      // Check if widget is still mounted before updating status
      if (_isMounted) {
        if (isTextMode) {
          widget.onStatusUpdate('Text message sent successfully to $ipAddress.');
          setState(() {
            _textToSend = null;
          });
        } else {
          widget.onStatusUpdate('File "${_selectedFile!.name}" sent successfully to $ipAddress.');
          // Optionally clear selection after sending
          // setState(() {
          //   _selectedFile = null;
          // });
        }
      }
    } catch (e) {
      if (_isMounted) {
        widget.onStatusUpdate('Error sending file: $e');
      }
      _cleanupResources(); // Ensure socket is closed on error
    } finally {
      _clientSocket = null; // Reset client socket
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Send Content', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Select Content to Send'),
                onPressed: _showFileSourceMenu,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),

              if (_selectedFile != null)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Selected file: ${_selectedFile!.name}'))
              else if (_textToSend != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Text to send (${_textToSend!.length} characters):', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: Text(_textToSend!.length > 100 ? '${_textToSend!.substring(0, 100)}...' : _textToSend!, style: const TextStyle(fontSize: 14)),
                      ),
                      TextButton(onPressed: _showTextInputDialog, child: const Text('Edit Text')),
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
                keyboardType: TextInputType.number, // Suggest numeric keyboard
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
                      ((_selectedFile == null && _textToSend == null) || _ipController.text.isEmpty)
                          ? null // Disable if no content or IP
                          : _sendFile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
