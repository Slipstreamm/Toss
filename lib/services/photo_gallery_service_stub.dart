import 'package:flutter/foundation.dart';

/// Stub implementation of PhotoGalleryService for non-mobile platforms
/// This implementation is used on desktop platforms (Windows/macOS/Linux)
class PhotoGalleryService {
  /// Stub implementation that always returns false
  static Future<bool> saveImageToGallery(String filePath) async {
    debugPrint('Photo gallery operations are not supported on this platform');
    return false;
  }

  /// Stub implementation that always returns false
  static Future<bool> saveVideoToGallery(String filePath) async {
    debugPrint('Photo gallery operations are not supported on this platform');
    return false;
  }
}
