import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/transfer_models.dart';
import '../services/crypto_service.dart';
import '../services/theme_service.dart';
import '../services/file_service.dart';
import '../services/hash_service.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key, required this.onStatusUpdate});

  final Function(String) onStatusUpdate;

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> with WidgetsBindingObserver {
  String? _localIpAddress;
  ServerSocket? _serverSocket;
  bool _isListening = false;
  StreamSubscription? _serverSubscription;

  // List to track received items in the current session
  final List<TransferItem> _receivedItems = [];

  // Service for verifying SHA256 hashes
  final HashService _hashService = HashService();

  // Service for encryption/decryption
  final CryptoService _cryptoService = CryptoService();

  // Map to store received hashes by batch ID
  final Map<String, Map<String, String>> _receivedHashes = {};

  // Flag to track if the widget is mounted
  bool _isMounted = true;

  // Flag to track if a transfer is in progress
  bool _isReceiving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getLocalIpAddress();

    // Check if auto-start server is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted) return;
      final themeService = Provider.of<ThemeService>(context, listen: false);
      if (themeService.settings.autoStartServer) {
        _startServer();
      }
    });
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
    super.dispose();
  }

  // Clean up all resources
  void _cleanupResources() {
    _serverSubscription?.cancel();
    _serverSubscription = null;
    _serverSocket?.close();
    _serverSocket = null;
    _isListening = false;
  }

  Future<void> _getLocalIpAddress() async {
    try {
      // First try using NetworkInfo
      final info = NetworkInfo();
      String? ip = await info.getWifiIP();

      // If NetworkInfo fails or returns null/empty/loopback, try NetworkInterface
      if (ip == null || ip.isEmpty || ip == '127.0.0.1' || ip == '::1') {
        ip = await _getLocalIpAddressFromInterfaces();
      }

      if (_isMounted) {
        setState(() {
          _localIpAddress = ip;
        });
        widget.onStatusUpdate('Ready');
      }
    } catch (e) {
      if (_isMounted) {
        widget.onStatusUpdate('Error getting IP: $e');
        setState(() {
          _localIpAddress = 'N/A';
        });
      }
    }
  }

  // Get the local IP address using network interfaces
  Future<String?> _getLocalIpAddressFromInterfaces() async {
    try {
      final interfaces = await NetworkInterface.list(includeLinkLocal: false, type: InternetAddressType.IPv4);

      // Find the first non-loopback IPv4 address
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          final ip = addr.address;
          if (!ip.startsWith('127.') && !ip.startsWith('0.') && ip != '::1') {
            return ip;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting local IP address from interfaces: $e');
      return null;
    }
  }

  Future<void> _startServer() async {
    if (_isListening) {
      widget.onStatusUpdate('Already listening.');
      return;
    }

    widget.onStatusUpdate('Starting server...');
    if (_isMounted) {
      setState(() {
        _isListening = true;
      });
    } else {
      return; // Exit if not mounted
    }

    try {
      // Check if still mounted before accessing context
      if (!_isMounted) return;

      final themeService = Provider.of<ThemeService>(context, listen: false);
      final serverPort = themeService.settings.serverPort;

      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, serverPort);

      // Check if still mounted before continuing
      if (!_isMounted) {
        _cleanupResources();
        return;
      }

      // Refresh IP address when server starts
      if (_localIpAddress == null || _localIpAddress!.isEmpty || _localIpAddress == 'N/A') {
        await _getLocalIpAddress();
      }

      widget.onStatusUpdate('Listening on ${_localIpAddress ?? '?.?.?.?'}:$serverPort');

      // Store the subscription so we can cancel it later
      _serverSubscription = _serverSocket!.listen(
        (Socket client) {
          // Check if still mounted before handling connection
          if (!_isMounted) {
            client.destroy();
            return;
          }
          widget.onStatusUpdate('Connection received from ${client.remoteAddress.address}:${client.remotePort}');
          _handleConnection(client);
        },
        onDone: () {
          // Check if still mounted before updating state
          if (_isMounted) {
            widget.onStatusUpdate('Server stopped.');
            if (_isMounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (e) {
          // Check if still mounted before updating state
          if (_isMounted) {
            widget.onStatusUpdate('Server error: $e');
            if (_isMounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        cancelOnError: true, // Close server on error
      );
    } catch (e) {
      // Check if still mounted before updating state
      if (_isMounted) {
        widget.onStatusUpdate('Error starting server: $e');
        if (_isMounted) {
          setState(() {
            _isListening = false;
          });
        }
      }
    }
  }

  void _stopServer() {
    if (!_isListening) {
      if (_isMounted) {
        widget.onStatusUpdate('Server is not running.');
      }
      return;
    }

    // Clean up all resources
    _cleanupResources();

    if (_isMounted) {
      widget.onStatusUpdate('Server stopped.');
      if (_isMounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  // Format file size to human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Verify a file against its hash
  Future<bool> _verifyFile(String filePath, String expectedHash) async {
    try {
      return await _hashService.verifyFileHash(filePath, expectedHash);
    } catch (e) {
      debugPrint('Error verifying file hash: $e');
      return false;
    }
  }

  // Verify text against its hash
  bool _verifyText(String text, String expectedHash) {
    try {
      return _hashService.verifyStringHash(text, expectedHash);
    } catch (e) {
      debugPrint('Error verifying text hash: $e');
      return false;
    }
  }

  void _handleConnection(Socket client) {
    List<int> buffer = [];
    StreamSubscription? clientSubscription;

    // Set receiving state
    if (_isMounted) {
      setState(() {
        _isReceiving = true;
      });
    }

    clientSubscription = client.listen(
      (Uint8List data) async {
        // Check if widget is still mounted before proceeding
        if (!_isMounted) {
          clientSubscription?.cancel();
          client.destroy();
          return;
        }

        buffer.addAll(data);
        // Basic check if buffer seems complete (ends with '}') - Improve this logic
        // A more robust approach would involve sending the size first or using delimiters
        try {
          String receivedData = utf8.decode(buffer);
          // Look for a potential end-of-JSON marker, very basic
          if (receivedData.trim().endsWith('}')) {
            var jsonMap = jsonDecode(receivedData);

            // Check if widget is still mounted before accessing context
            if (!_isMounted) {
              clientSubscription?.cancel();
              client.destroy();
              return;
            }

            final themeService = Provider.of<ThemeService>(context, listen: false);
            final fileService = FileService();

            // Check if this is a batch transfer (new protocol) or single item (old protocol)
            if (jsonMap.containsKey('protocol') && jsonMap['protocol'].toString().startsWith('toss-v')) {
              // This is a batch transfer using the new protocol
              final transferBatch = TransferBatch.fromJson(jsonMap);
              final batchId = transferBatch.id;
              List<TransferItem> items;

              // Check if this is an encrypted batch (protocol v4+)
              if (transferBatch.isEncrypted && transferBatch.encryptedData != null) {
                widget.onStatusUpdate('Received encrypted data. Attempting to decrypt...');

                // Get the encryption PIN from settings
                final encryptionPin = themeService.settings.encryptionPin;

                try {
                  // Decrypt the data
                  final decryptedJson = await _cryptoService.decrypt(transferBatch.encryptedData!, encryptionPin);

                  // Parse the decrypted JSON into a TransferBatch
                  final decryptedBatch = TransferBatch.fromJson(jsonDecode(decryptedJson));

                  // Replace the encrypted batch with the decrypted one
                  widget.onStatusUpdate('Data decrypted successfully.');

                  // Continue processing with the decrypted batch
                  items = decryptedBatch.items;

                  // Process the decrypted batch as usual
                  widget.onStatusUpdate('Processing decrypted batch of ${items.length} item(s)...');
                } catch (e) {
                  widget.onStatusUpdate('Error decrypting data: $e');
                  return; // Stop processing if decryption fails
                }
              } else {
                // Not encrypted, process as usual
                items = transferBatch.items;
              }

              // Check if this is a hash-only batch (protocol v3+)
              if (transferBatch.protocol == 'toss-v3' && transferBatch.isHashOnly) {
                widget.onStatusUpdate('Received hash information for batch $batchId. Waiting for data...');

                // Store the hashes for later verification
                final Map<String, String> hashMap = {};
                for (final item in items) {
                  if (item.hash != null) {
                    hashMap[item.id] = item.hash!;
                  }
                }

                _receivedHashes[batchId] = hashMap;
                return; // Wait for the actual data to arrive
              }

              widget.onStatusUpdate('Receiving batch of ${items.length} item(s)...');

              // Process each item in the batch
              for (final item in items) {
                if (item.type == TransferItemType.text && item.textContent != null) {
                  // Handle text data
                  final textData = item.textContent!;
                  bool isVerified = false;

                  // Check if we have a hash for this item
                  final storedHashes = _receivedHashes[batchId];
                  if (storedHashes != null && storedHashes.containsKey(item.id)) {
                    final expectedHash = storedHashes[item.id]!;
                    isVerified = _verifyText(textData, expectedHash);

                    if (isVerified) {
                      widget.onStatusUpdate('Verified text: ${item.name} - Hash matches');
                    } else {
                      widget.onStatusUpdate('WARNING: Text verification failed for ${item.name} - Hash mismatch!');
                    }
                  } else if (item.hash != null) {
                    // If the item has a hash included directly
                    isVerified = _verifyText(textData, item.hash!);

                    if (isVerified) {
                      widget.onStatusUpdate('Verified text: ${item.name} - Hash matches');
                    } else {
                      widget.onStatusUpdate('WARNING: Text verification failed for ${item.name} - Hash mismatch!');
                    }
                  }

                  // Add to received items list
                  if (_isMounted) {
                    setState(() {
                      _receivedItems.add(
                        TransferItem(
                          id: item.id,
                          type: item.type,
                          name: item.name,
                          size: item.size,
                          textContent: textData,
                          hash: item.hash ?? storedHashes?[item.id],
                          isSelected: true,
                          isVerified: isVerified,
                        ),
                      );
                    });
                  }

                  widget.onStatusUpdate('Received text message: ${item.name} (${textData.length} characters)');

                  // Show text received dialog if enabled in settings
                  if (_isMounted && themeService.settings.confirmBeforeReceiving) {
                    _showTextReceivedDialog(textData, isVerified);
                  }
                } else if (item.type == TransferItemType.file && item.bytes != null) {
                  // Handle file data
                  try {
                    final savedFilePath = await fileService.saveFile(item.name, item.bytes!);
                    bool isVerified = false;

                    // Check if we have a hash for this item
                    final storedHashes = _receivedHashes[batchId];
                    if (storedHashes != null && storedHashes.containsKey(item.id)) {
                      final expectedHash = storedHashes[item.id]!;
                      isVerified = await _verifyFile(savedFilePath, expectedHash);

                      if (isVerified) {
                        widget.onStatusUpdate('Verified file: ${item.name} - Hash matches');
                      } else {
                        widget.onStatusUpdate('WARNING: File verification failed for ${item.name} - Hash mismatch!');
                      }
                    } else if (item.hash != null) {
                      // If the item has a hash included directly
                      isVerified = await _verifyFile(savedFilePath, item.hash!);

                      if (isVerified) {
                        widget.onStatusUpdate('Verified file: ${item.name} - Hash matches');
                      } else {
                        widget.onStatusUpdate('WARNING: File verification failed for ${item.name} - Hash mismatch!');
                      }
                    }

                    // Add to received items list with the saved path
                    if (_isMounted) {
                      setState(() {
                        _receivedItems.add(
                          TransferItem(
                            id: item.id,
                            type: item.type,
                            name: item.name,
                            path: savedFilePath,
                            size: item.size,
                            hash: item.hash ?? storedHashes?[item.id],
                            isSelected: true,
                            isVerified: isVerified,
                          ),
                        );
                      });
                    }

                    widget.onStatusUpdate('Received file: ${item.name} - Saved to: $savedFilePath');

                    // Show confirmation dialog if enabled in settings
                    if (_isMounted && themeService.settings.confirmBeforeReceiving) {
                      _showFileReceivedDialog(item.name, savedFilePath, isVerified);
                    }
                  } catch (e) {
                    if (_isMounted) {
                      widget.onStatusUpdate('Error saving file ${item.name}: $e');
                    }
                  }
                }
              }

              final encryptionStatus = transferBatch.isEncrypted ? ' (AES-256 encrypted)' : '';
              widget.onStatusUpdate('Completed receiving ${items.length} item(s)$encryptionStatus');
            } else {
              // Handle legacy single-item format for backward compatibility
              String contentType = jsonMap['type'] ?? 'file';

              if (contentType == 'text') {
                // Handle text data
                String textData = jsonMap['data'];

                // Create a TransferItem and add to received items
                final textItem = TransferItem.fromText(textData);

                if (_isMounted) {
                  setState(() {
                    _receivedItems.add(textItem);
                  });
                }

                widget.onStatusUpdate('Received text message (${textData.length} characters)');

                // Show text received dialog if enabled in settings
                if (_isMounted && themeService.settings.confirmBeforeReceiving) {
                  _showTextReceivedDialog(textData);
                }
              } else {
                // Handle file data
                String fileName = jsonMap['filename'];
                String fileContentBase64 = jsonMap['data'];
                Uint8List fileBytes = base64Decode(fileContentBase64);

                try {
                  final savedFilePath = await fileService.saveFile(fileName, fileBytes);

                  // Create a TransferItem and add to received items
                  final fileItem = TransferItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: TransferItemType.file,
                    name: fileName,
                    path: savedFilePath,
                    size: fileBytes.length,
                    isSelected: true,
                  );

                  if (_isMounted) {
                    setState(() {
                      _receivedItems.add(fileItem);
                    });
                  }

                  widget.onStatusUpdate('Received file: $fileName - Saved to: $savedFilePath');

                  // Show confirmation dialog if enabled in settings
                  if (_isMounted && themeService.settings.confirmBeforeReceiving) {
                    _showFileReceivedDialog(fileName, savedFilePath);
                  }
                } catch (e) {
                  if (_isMounted) {
                    widget.onStatusUpdate('Error saving file: $e');
                  }
                }
              }
            }

            // Close the client connection after receiving the file
            clientSubscription?.cancel();
            client.close();
            buffer.clear(); // Clear buffer for next potential message (if any)
          }
        } catch (e) {
          // Handle potential JSON decoding errors or incomplete data
          debugPrint('Error processing received data: $e');
          // Don't close the client immediately, maybe more data is coming
          // Consider adding a timeout or better framing mechanism
        }
      },
      onDone: () {
        if (_isMounted) {
          widget.onStatusUpdate('Client disconnected: ${client.remoteAddress.address}');
          setState(() {
            _isReceiving = false;
          });
        }
        clientSubscription?.cancel();
        client.destroy();
      },
      onError: (e) {
        if (_isMounted) {
          widget.onStatusUpdate('Client connection error: $e');
          setState(() {
            _isReceiving = false;
          });
        }
        clientSubscription?.cancel();
        client.destroy();
      },
      cancelOnError: true,
    );
  }

  // Show dialog when a file is received
  void _showFileReceivedDialog(String fileName, String filePath, [bool isVerified = false]) {
    // Double-check that we're still mounted before showing dialog
    if (!_isMounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('File Received'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: $fileName'),
                const SizedBox(height: 8),
                Text('Saved to: $filePath', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(isVerified ? Icons.verified_user : Icons.warning, color: isVerified ? Colors.green : Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? 'Verified: SHA256 hash matches' : 'Warning: SHA256 hash verification failed',
                      style: TextStyle(fontSize: 12, color: isVerified ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              if (Platform.isAndroid || Platform.isIOS)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    FileService().shareFile(filePath);
                  },
                  child: const Text('Share'),
                ),
              if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    FileService().openContainingDirectory(filePath);
                  },
                  child: const Text('Show in Folder'),
                ),
            ],
          ),
    );
  }

  // Show dialog when text is received
  void _showTextReceivedDialog(String textData, [bool isVerified = false]) {
    // Double-check that we're still mounted before showing dialog
    if (!_isMounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Text Message Received'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Message (${textData.length} characters):', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                  child: SingleChildScrollView(child: Text(textData)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(isVerified ? Icons.verified_user : Icons.warning, color: isVerified ? Colors.green : Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? 'Verified: SHA256 hash matches' : 'Warning: SHA256 hash verification failed',
                      style: TextStyle(fontSize: 12, color: isVerified ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: textData));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text copied to clipboard')));
                  Navigator.pop(context);
                },
                child: const Text('Copy to Clipboard'),
              ),
            ],
          ),
    );
  }

  // Clear received items list
  void _clearReceivedItems() {
    setState(() {
      _receivedItems.clear();
    });
    widget.onStatusUpdate('Received items list cleared');
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
              Text('Receive Content', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: Text('Your IP Address: ${_localIpAddress ?? "Loading..."}', style: Theme.of(context).textTheme.titleMedium)),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh IP Address',
                    onPressed: () {
                      setState(() {
                        _localIpAddress = 'Refreshing...';
                      });
                      _getLocalIpAddress();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text('Receive Files & Text (Act as Server)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Listening'),
                    onPressed: _isReceiving || _isListening ? null : _startServer, // Disable if already listening or receiving
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Listening'),
                    onPressed: _isReceiving || !_isListening ? null : _stopServer, // Disable if not listening or receiving
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Icon(_isListening ? Icons.circle : Icons.circle_outlined, color: _isListening ? Colors.green : Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${_isListening ? "Listening" : "Not Listening"}${_isReceiving ? " (Receiving...)" : ""}',
                    style: TextStyle(color: _isListening ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              if (_receivedItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Received Items (${_receivedItems.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.clear_all), tooltip: 'Clear received items list', onPressed: _isReceiving ? null : _clearReceivedItems),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _receivedItems.length,
                    itemBuilder: (context, index) {
                      final item = _receivedItems[index];
                      return ListTile(
                        dense: true,
                        title: Row(
                          children: [
                            Text(item.name, overflow: TextOverflow.ellipsis),
                            const SizedBox(width: 4),
                            if (item.hash != null)
                              Icon(item.isVerified ? Icons.verified_user : Icons.warning, color: item.isVerified ? Colors.green : Colors.orange, size: 14),
                          ],
                        ),
                        subtitle: Text(item.type == TransferItemType.file ? 'File: ${_formatFileSize(item.size)}' : 'Text: ${_formatFileSize(item.size)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.type == TransferItemType.file && item.path != null)
                              IconButton(
                                icon: const Icon(Icons.folder_open, size: 20),
                                tooltip: 'Open containing folder',
                                onPressed: () => FileService().openContainingDirectory(item.path!),
                              ),
                            if (item.type == TransferItemType.text && item.textContent != null)
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 20),
                                tooltip: 'View text',
                                onPressed: () => _showTextReceivedDialog(item.textContent!, item.isVerified),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
