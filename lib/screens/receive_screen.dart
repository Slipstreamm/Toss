import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';
import '../services/file_service.dart';

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

  // Flag to track if the widget is mounted
  bool _isMounted = true;

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

  void _handleConnection(Socket client) {
    List<int> buffer = [];
    StreamSubscription? clientSubscription;

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
            String contentType = jsonMap['type'] ?? 'file'; // Default to 'file' for backward compatibility

            // Check if widget is still mounted before accessing context
            if (!_isMounted) {
              clientSubscription?.cancel();
              client.destroy();
              return;
            }

            final themeService = Provider.of<ThemeService>(context, listen: false);

            if (contentType == 'text') {
              // Handle text data
              String textData = jsonMap['data'];

              // Check if widget is still mounted before updating status
              if (_isMounted) {
                widget.onStatusUpdate('Received text message (${textData.length} characters)');

                // Show text received dialog if enabled in settings
                if (_isMounted && themeService.settings.confirmBeforeReceiving) {
                  _showTextReceivedDialog(textData);
                }
              }
            } else {
              // Handle file data
              String fileName = jsonMap['filename'];
              String fileContentBase64 = jsonMap['data'];
              Uint8List fileBytes = base64Decode(fileContentBase64);

              // Save the file using FileService
              final fileService = FileService();

              try {
                final savedFilePath = await fileService.saveFile(fileName, fileBytes);

                // Check if widget is still mounted before updating status
                if (_isMounted) {
                  widget.onStatusUpdate('Received file: $fileName - Saved to: $savedFilePath');

                  // Show confirmation dialog if enabled in settings
                  if (_isMounted && themeService.settings.confirmBeforeReceiving) {
                    _showFileReceivedDialog(fileName, savedFilePath);
                  }
                }
              } catch (e) {
                if (_isMounted) {
                  widget.onStatusUpdate('Error saving file: $e');
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
        }
        clientSubscription?.cancel();
        client.destroy();
      },
      onError: (e) {
        if (_isMounted) {
          widget.onStatusUpdate('Client connection error: $e');
        }
        clientSubscription?.cancel();
        client.destroy();
      },
      cancelOnError: true,
    );
  }

  // Show dialog when a file is received
  void _showFileReceivedDialog(String fileName, String filePath) {
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
              children: [Text('File: $fileName'), const SizedBox(height: 8), Text('Saved to: $filePath', style: const TextStyle(fontSize: 12))],
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
  void _showTextReceivedDialog(String textData) {
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
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: textData));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text copied to clipboard')));
                },
                child: const Text('Copy to Clipboard'),
              ),
            ],
          ),
    );
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
                    onPressed: _isListening ? null : _startServer, // Disable if already listening
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Listening'),
                    onPressed: !_isListening ? null : _stopServer, // Disable if not listening
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Status: ${_isListening ? "Listening" : "Not Listening"}',
                style: TextStyle(color: _isListening ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
