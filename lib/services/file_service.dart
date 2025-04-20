import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/settings_model.dart';
import 'settings_service.dart';

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

  /// Share a file (primarily for mobile platforms)
  Future<void> shareFile(String filePath) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await Share.shareXFiles([XFile(filePath)]);
        debugPrint('Share result: ${result.status}');
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
}
