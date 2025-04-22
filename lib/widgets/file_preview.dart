import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:universal_file_viewer/universal_file_viewer.dart';
import '../models/transfer_models.dart';

/// A widget that displays a preview of a file based on its type
class FilePreview extends StatefulWidget {
  final TransferItem item;
  final bool fullscreen;

  const FilePreview({super.key, required this.item, this.fullscreen = false});

  @override
  State<FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<FilePreview> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  Future<void> _initializePreview() async {
    if (widget.item.type != TransferItemType.file || widget.item.previewType == null) {
      return;
    }

    // Initialize video player if it's a video file
    if (widget.item.previewType == FilePreviewType.video && widget.item.path != null) {
      try {
        _videoController = VideoPlayerController.file(File(widget.item.path!));
        await _videoController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoController!.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(child: Text('Error: $errorMessage', style: const TextStyle(color: Colors.white)));
          },
        );

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Error initializing video player: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.type != TransferItemType.file) {
      return const Center(child: Text('Not a file'));
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const Icon(Icons.error_outline, size: 48, color: Colors.red), const SizedBox(height: 16), Text('Error loading ${widget.item.name}')],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Build preview based on file type
    switch (widget.item.previewType) {
      case FilePreviewType.image:
        return _buildImagePreview();
      case FilePreviewType.video:
        return _buildVideoPreview();
      case FilePreviewType.audio:
        return _buildAudioPreview();
      case FilePreviewType.pdf:
        return _buildPdfPreview();
      case FilePreviewType.text:
        return _buildTextPreview();
      case FilePreviewType.other:
      default:
        return _buildGenericPreview();
    }
  }

  Widget _buildImagePreview() {
    // If we have a path, use it
    if (widget.item.path != null) {
      return widget.fullscreen
          ? InteractiveViewer(minScale: 0.5, maxScale: 3.0, child: Image.file(File(widget.item.path!), fit: BoxFit.contain))
          : Image.file(File(widget.item.path!), fit: BoxFit.cover);
    }

    // If we have bytes but no path, use memory image
    if (widget.item.bytes != null) {
      return widget.fullscreen
          ? InteractiveViewer(minScale: 0.5, maxScale: 3.0, child: Image.memory(widget.item.bytes!, fit: BoxFit.contain))
          : Image.memory(widget.item.bytes!, fit: BoxFit.cover);
    }

    // If we have neither path nor bytes
    return const Center(child: Text('Image data is missing'));
  }

  Widget _buildVideoPreview() {
    if (_chewieController == null) {
      // If we have bytes but no controller yet, show a placeholder with play button
      if (widget.item.bytes != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_file, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              Text(widget.item.name, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Text('Save the file to play video', style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      }
      return const Center(child: Text('Video could not be loaded'));
    }

    return Chewie(controller: _chewieController!);
  }

  Widget _buildAudioPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.audio_file, size: 72, color: Colors.blue),
          const SizedBox(height: 16),
          Text(widget.item.name, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    if (widget.item.path == null) {
      // If we have bytes but no path, show a placeholder
      if (widget.item.bytes != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              Text(widget.item.name, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Text('Save the file to view PDF', style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      }
      return const Center(child: Text('PDF path is missing'));
    }

    return UniversalFileViewer(file: File(widget.item.path!));
  }

  Widget _buildTextPreview() {
    if (widget.item.path == null) {
      // If we have bytes but no path, try to show the text content
      if (widget.item.bytes != null) {
        try {
          final textContent = String.fromCharCodes(widget.item.bytes!);
          return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text(textContent));
        } catch (e) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description, size: 72, color: Colors.blue),
                const SizedBox(height: 16),
                Text(widget.item.name, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                const Text('Save the file to view text content', style: TextStyle(fontSize: 14)),
              ],
            ),
          );
        }
      }
      return const Center(child: Text('Text file path is missing'));
    }

    return FutureBuilder<String>(
      future: File(widget.item.path!).readAsString(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No text content'));
        }

        return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text(snapshot.data!));
      },
    );
  }

  Widget _buildGenericPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(widget.item.name, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('${(widget.item.size / 1024).toStringAsFixed(2)} KB', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}

/// A widget that displays a thumbnail preview of a file
class FilePreviewThumbnail extends StatelessWidget {
  final TransferItem item;
  final double size;
  final VoidCallback? onTap;

  const FilePreviewThumbnail({super.key, required this.item, this.size = 80, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget thumbnail;

    if (item.type == TransferItemType.text) {
      // Handle text items
      thumbnail = _buildGenericThumbnail(Icons.text_snippet, Colors.blue);
    } else {
      // Handle file items
      switch (item.previewType) {
        case FilePreviewType.image:
          thumbnail = _buildImageThumbnail();
          break;
        case FilePreviewType.video:
          thumbnail = _buildGenericThumbnail(Icons.video_file, Colors.red);
          break;
        case FilePreviewType.audio:
          thumbnail = _buildGenericThumbnail(Icons.audio_file, Colors.orange);
          break;
        case FilePreviewType.pdf:
          thumbnail = _buildGenericThumbnail(Icons.picture_as_pdf, Colors.red);
          break;
        case FilePreviewType.text:
          thumbnail = _buildGenericThumbnail(Icons.description, Colors.blue);
          break;
        case FilePreviewType.other:
        default:
          thumbnail = _buildGenericThumbnail(Icons.insert_drive_file, Colors.grey);
          break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: size, height: size, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: thumbnail)),
    );
  }

  Widget _buildImageThumbnail() {
    // If we have a path, use it
    if (item.path != null) {
      return Image.file(
        File(item.path!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildGenericThumbnail(Icons.broken_image, Colors.red);
        },
      );
    }

    // If we have bytes but no path, use memory image
    if (item.bytes != null) {
      return Image.memory(
        item.bytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildGenericThumbnail(Icons.broken_image, Colors.red);
        },
      );
    }

    // If we have neither path nor bytes
    return _buildGenericThumbnail(Icons.image, Colors.green);
  }

  Widget _buildGenericThumbnail(IconData icon, Color color) {
    return Container(color: color.withAlpha(25), child: Center(child: Icon(icon, size: size * 0.5, color: color)));
  }
}
