import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../models/transfer_models.dart';
import '../services/file_service.dart';
import '../widgets/file_preview.dart';
import '../widgets/save_file_dialog.dart';

/// A screen that displays received files and allows the user to save them
class ReceivedFilesScreen extends StatefulWidget {
  final List<TransferItem> receivedItems;
  final Function(String) onStatusUpdate;
  final VoidCallback? onClose;

  const ReceivedFilesScreen({super.key, required this.receivedItems, required this.onStatusUpdate, this.onClose});

  @override
  State<ReceivedFilesScreen> createState() => _ReceivedFilesScreenState();
}

class _ReceivedFilesScreenState extends State<ReceivedFilesScreen> {
  final FileService _fileService = FileService();
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Call onClose callback if provided
    widget.onClose?.call();
    super.dispose();
  }

  Future<void> _showSaveDialog(TransferItem item) async {
    final result = await showDialog<String>(context: context, builder: (context) => SaveFileDialog(item: item));

    if (result != null) {
      widget.onStatusUpdate('File saved: ${item.name} - Saved to: $result');
      setState(() {}); // Refresh UI to update saved status
    }
  }

  Future<void> _openFile(TransferItem item) async {
    if (item.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File must be saved before opening')));
      return;
    }

    try {
      final result = await _fileService.openFile(item.path!);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening file: ${result.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  Future<void> _shareFile(TransferItem item) async {
    if (item.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File must be saved before sharing')));
      return;
    }

    try {
      await _fileService.shareFile(item.path!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing file: $e')));
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Received Files (${widget.receivedItems.length})'),
        actions: [
          if (widget.receivedItems.isNotEmpty && widget.receivedItems[_currentIndex].type == TransferItemType.file) ...[
            IconButton(icon: const Icon(Icons.save), tooltip: 'Save File', onPressed: () => _showSaveDialog(widget.receivedItems[_currentIndex])),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open File',
              onPressed: widget.receivedItems[_currentIndex].isSaved ? () => _openFile(widget.receivedItems[_currentIndex]) : null,
            ),
            if (Platform.isAndroid || Platform.isIOS)
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share File',
                onPressed: widget.receivedItems[_currentIndex].isSaved ? () => _shareFile(widget.receivedItems[_currentIndex]) : null,
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Main preview area
          Expanded(
            flex: 3,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.receivedItems.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final item = widget.receivedItems[index];

                if (item.type == TransferItemType.text) {
                  return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text(item.textContent ?? 'No text content')));
                } else {
                  return FilePreview(item: item, fullscreen: true);
                }
              },
            ),
          ),

          // File info bar
          if (widget.receivedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.receivedItems[_currentIndex].name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatFileSize(widget.receivedItems[_currentIndex].size),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(179)),
                        ),
                      ],
                    ),
                  ),
                  if (widget.receivedItems[_currentIndex].isSaved) const Icon(Icons.check_circle, color: Colors.green, size: 16),
                ],
              ),
            ),

          // Thumbnails of all files
          if (widget.receivedItems.length > 1)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.receivedItems.length,
                itemBuilder: (context, index) {
                  final item = widget.receivedItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: FilePreviewThumbnail(
                            item: item,
                            size: 70,
                            onTap: () {
                              _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == index ? Theme.of(context).colorScheme.primary : Colors.grey.withAlpha(77),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save All'),
              onPressed: () async {
                for (final item in widget.receivedItems) {
                  if (item.type == TransferItemType.file && !item.isSaved && item.bytes != null) {
                    try {
                      final path = await _fileService.saveFile(item.name, item.bytes!);
                      item.path = path;
                      item.isSaved = true;
                      widget.onStatusUpdate('File saved: ${item.name} - Saved to: $path');
                    } catch (e) {
                      widget.onStatusUpdate('Error saving file ${item.name}: $e');
                    }
                  }
                }
                setState(() {}); // Refresh UI
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.folder),
              label: const Text('Choose Location'),
              onPressed: () async {
                final item = widget.receivedItems[_currentIndex];
                if (item.type == TransferItemType.file) {
                  await _showSaveDialog(item);
                }
              },
            ),
            if (Platform.isAndroid || Platform.isIOS)
              TextButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Save to Gallery'),
                onPressed: () async {
                  final item = widget.receivedItems[_currentIndex];
                  if (item.type == TransferItemType.file && _fileService.isMediaFile(item.name)) {
                    if (item.path == null && item.bytes != null) {
                      // First save to a temporary location
                      try {
                        final tempPath = await _fileService.saveFile(item.name, item.bytes!);
                        item.path = tempPath;

                        bool success = false;
                        if (_fileService.isImageFile(item.name)) {
                          success = await _fileService.saveToPhotoGallery(tempPath);
                        } else if (_fileService.isVideoFile(item.name)) {
                          success = await _fileService.saveVideoToPhotoGallery(tempPath);
                        }

                        if (success) {
                          item.isSaved = true;
                          widget.onStatusUpdate('File saved to gallery: ${item.name}');
                          setState(() {}); // Refresh UI
                        } else {
                          widget.onStatusUpdate('Failed to save to gallery: ${item.name}');
                        }
                      } catch (e) {
                        widget.onStatusUpdate('Error saving to gallery: $e');
                      }
                    } else if (item.path != null) {
                      // File already saved, just save to gallery
                      try {
                        bool success = false;
                        if (_fileService.isImageFile(item.name)) {
                          success = await _fileService.saveToPhotoGallery(item.path!);
                        } else if (_fileService.isVideoFile(item.name)) {
                          success = await _fileService.saveVideoToPhotoGallery(item.path!);
                        }

                        if (success) {
                          widget.onStatusUpdate('File saved to gallery: ${item.name}');
                        } else {
                          widget.onStatusUpdate('Failed to save to gallery: ${item.name}');
                        }
                      } catch (e) {
                        widget.onStatusUpdate('Error saving to gallery: $e');
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only media files can be saved to gallery')));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
