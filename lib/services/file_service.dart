import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../models/settings_model.dart';
import '../models/transfer_models.dart';
import 'settings_service.dart';

// Import the platform-specific photo gallery service
import 'photo_gallery_service.dart';

class FileService {
  final SettingsService _settingsService = SettingsService();

  // Singleton pattern
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// Save a file to the appropriate location based on platform and settings
  Future<String> saveFile(String fileName, List<int> fileBytes) async {
    try {
      final settings = await _settingsService.loadSettings();
      final filePath = await _getFileSavePath(fileName, settings);

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      debugPrint('File saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving file: $e');
      rethrow;
    }
  }

  /// Save a file to a custom location chosen by the user
  Future<String?> saveFileToCustomLocation(String fileName, List<int> fileBytes) async {
    try {
      // Let user pick a directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // User cancelled the picker
        return null;
      }

      final filePath = path.join(selectedDirectory, fileName);
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      debugPrint('File saved to custom location: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving file to custom location: $e');
      rethrow;
    }
  }

  /// Save a file to a specific directory
  Future<String> saveFileToDirectory(String fileName, List<int> fileBytes, String directory) async {
    try {
      final filePath = path.join(directory, fileName);
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      debugPrint('File saved to directory: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving file to directory: $e');
      rethrow;
    }
  }

  /// Get the appropriate file save path based on platform and settings
  Future<String> _getFileSavePath(String fileName, SettingsModel settings) async {
    // If user has set a custom save location and it exists, use it
    if (settings.defaultSaveLocation.isNotEmpty) {
      final directory = Directory(settings.defaultSaveLocation);
      if (await directory.exists()) {
        return path.join(settings.defaultSaveLocation, fileName);
      }
    }

    // Otherwise use platform-specific default location
    Directory? directory;

    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile, use the downloads directory
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop, use the downloads directory
      directory = await getDownloadsDirectory();
    } else {
      // Fallback to temporary directory for other platforms
      directory = await getTemporaryDirectory();
    }

    // If we couldn't get a directory, use the current directory
    final savePath = directory?.path ?? Directory.current.path;
    return path.join(savePath, fileName);
  }

  /// Save multiple files at once
  Future<List<String>> saveFiles(List<TransferItem> items) async {
    final List<String> savedPaths = [];
    final settings = await _settingsService.loadSettings();

    for (final item in items) {
      if (item.type == TransferItemType.file && item.bytes != null) {
        try {
          final filePath = await _getFileSavePath(item.name, settings);
          final file = File(filePath);
          await file.writeAsBytes(item.bytes!);
          savedPaths.add(filePath);
          debugPrint('File saved to: $filePath');
        } catch (e) {
          debugPrint('Error saving file ${item.name}: $e');
          // Continue with other files even if one fails
        }
      }
    }

    return savedPaths;
  }

  /// Share a file (primarily for mobile platforms)
  Future<void> shareFile(String filePath) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
        debugPrint('File shared: $filePath, status: ${result.status}');
      } else {
        // On desktop, just show the file location
        debugPrint('File is located at: $filePath');
        // Could implement desktop-specific sharing here if needed
      }
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }

  /// Share multiple files (primarily for mobile platforms)
  Future<void> shareFiles(List<String> filePaths) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final files = filePaths.map((path) => XFile(path)).toList();
        final result = await SharePlus.instance.share(ShareParams(files: files));
        debugPrint('Files shared: ${filePaths.length} files, status: ${result.status}');
      } else {
        // On desktop, just show the file location of the first file
        if (filePaths.isNotEmpty) {
          await openContainingDirectory(filePaths.first);
        }
      }
    } catch (e) {
      debugPrint('Error sharing files: $e');
      rethrow;
    }
  }

  /// Open the directory containing a file
  Future<void> openContainingDirectory(String filePath) async {
    try {
      final directory = path.dirname(filePath);

      if (Platform.isWindows) {
        await Process.run('explorer', [directory]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [directory]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      }
      // For mobile platforms, this operation doesn't make sense
    } catch (e) {
      debugPrint('Error opening directory: $e');
    }
  }

  /// Open a file with the default app
  Future<OpenResult> openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      debugPrint('Open file result: ${result.message}');
      return result;
    } catch (e) {
      debugPrint('Error opening file: $e');
      return OpenResult(type: ResultType.error, message: e.toString());
    }
  }

  /// Save a media file to the device's photo gallery (mobile only)
  Future<bool> saveToPhotoGallery(String filePath) async {
    try {
      if (!(Platform.isAndroid || Platform.isIOS)) {
        debugPrint('Saving to photo gallery is only supported on mobile platforms');
        return false;
      }

      // Use the platform-specific implementation
      return await PhotoGalleryService.saveImageToGallery(filePath);
    } catch (e) {
      debugPrint('Error saving to photo gallery: $e');
      return false;
    }
  }

  /// Save a video to the device's photo gallery (mobile only)
  Future<bool> saveVideoToPhotoGallery(String filePath) async {
    try {
      if (!(Platform.isAndroid || Platform.isIOS)) {
        debugPrint('Saving to photo gallery is only supported on mobile platforms');
        return false;
      }

      // Use the platform-specific implementation
      return await PhotoGalleryService.saveVideoToGallery(filePath);
    } catch (e) {
      debugPrint('Error saving video to photo gallery: $e');
      return false;
    }
  }

  /// Check if a file is a media file (image or video)
  bool isMediaFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'];
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.3gp'];

    return imageExtensions.contains(extension) || videoExtensions.contains(extension);
  }

  /// Check if a file is an image
  bool isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'];

    return imageExtensions.contains(extension);
  }

  /// Check if a file is a video
  bool isVideoFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.3gp'];

    return videoExtensions.contains(extension);
  }
}
