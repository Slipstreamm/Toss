import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

// Import the appropriate implementation based on platform
import 'photo_gallery_service_stub.dart' if (dart.library.io) 'photo_gallery_service_mobile.dart';

/// Service for interacting with the device's photo gallery
class PhotoGalleryService {
  /// Check if the current platform supports photo gallery operations
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Save an image to the device's photo gallery
  static Future<bool> saveImageToGallery(String filePath) async {
    if (!isSupported) {
      debugPrint('Photo gallery operations are not supported on this platform');
      return false;
    }

    // This will call the implementation from the conditionally imported file
    return await PhotoGalleryServiceImpl.saveImageToGallery(filePath);
  }

  /// Save a video to the device's photo gallery
  static Future<bool> saveVideoToGallery(String filePath) async {
    if (!isSupported) {
      debugPrint('Photo gallery operations are not supported on this platform');
      return false;
    }

    // This will call the implementation from the conditionally imported file
    return await PhotoGalleryServiceImpl.saveVideoToGallery(filePath);
  }
}
