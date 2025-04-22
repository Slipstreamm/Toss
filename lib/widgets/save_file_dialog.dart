import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transfer_models.dart';
import '../services/file_service.dart';

/// A dialog for choosing where to save a file
class SaveFileDialog extends StatefulWidget {
  final TransferItem item;

  const SaveFileDialog({
    super.key,
    required this.item,
  });

  @override
  State<SaveFileDialog> createState() => _SaveFileDialogState();
}

class _SaveFileDialogState extends State<SaveFileDialog> {
  final FileService _fileService = FileService();
  bool _isSaving = false;
  String? _errorMessage;
  bool _isMediaFile = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.path != null) {
      _isMediaFile = _fileService.isMediaFile(widget.item.path!);
    }
  }

  Future<void> _saveToDefaultLocation() async {
    if (widget.item.bytes == null) {
      setState(() {
        _errorMessage = 'File data is missing';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final savedPath = await _fileService.saveFile(widget.item.name, widget.item.bytes!);
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        // Update the item with the saved path
        widget.item.path = savedPath;
        widget.item.isSaved = true;
        
        Navigator.of(context).pop(savedPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Error saving file: $e';
        });
      }
    }
  }

  Future<void> _saveToCustomLocation() async {
    if (widget.item.bytes == null) {
      setState(() {
        _errorMessage = 'File data is missing';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final savedPath = await _fileService.saveFileToCustomLocation(widget.item.name, widget.item.bytes!);
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        if (savedPath != null) {
          // Update the item with the saved path
          widget.item.path = savedPath;
          widget.item.isSaved = true;
          
          Navigator.of(context).pop(savedPath);
        } else {
          // User cancelled the directory picker
          setState(() {
            _errorMessage = 'Save cancelled';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Error saving file: $e';
        });
      }
    }
  }

  Future<void> _saveToPhotoGallery() async {
    if (widget.item.bytes == null) {
      setState(() {
        _errorMessage = 'File data is missing';
      });
      return;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _errorMessage = 'Photo gallery is only available on mobile devices';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // First save to a temporary location
      final tempPath = await _fileService.saveFile(widget.item.name, widget.item.bytes!);
      bool success = false;
      
      // Then save to photo gallery
      if (_fileService.isImageFile(widget.item.name)) {
        success = await _fileService.saveToPhotoGallery(tempPath);
      } else if (_fileService.isVideoFile(widget.item.name)) {
        success = await _fileService.saveVideoToPhotoGallery(tempPath);
      }
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        if (success) {
          // Update the item with the saved path
          widget.item.path = tempPath;
          widget.item.isSaved = true;
          
          Navigator.of(context).pop(tempPath);
        } else {
          setState(() {
            _errorMessage = 'Failed to save to photo gallery';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Error saving to photo gallery: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('File: ${widget.item.name}'),
          const SizedBox(height: 8),
          Text('Size: ${_formatFileSize(widget.item.size)}'),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          if (_isSaving) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _saveToDefaultLocation,
          child: const Text('Save to Default Location'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _saveToCustomLocation,
          child: const Text('Choose Location...'),
        ),
        if (_isMediaFile && (Platform.isAndroid || Platform.isIOS))
          TextButton(
            onPressed: _isSaving ? null : _saveToPhotoGallery,
            child: const Text('Save to Gallery'),
          ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
