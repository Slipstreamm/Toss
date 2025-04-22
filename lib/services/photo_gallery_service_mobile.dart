// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;

/// Service for interacting with the device's photo gallery
/// This implementation is used on mobile platforms (Android/iOS)
class PhotoGalleryService {
  /// Save an image to the device's photo gallery
  static Future<bool> saveImageToGallery(String filePath) async {
    try {
      // Request permission
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        debugPrint('Permission to access photo gallery denied');
        return false;
      }

      // Get file info
      final String title = path.basename(filePath);

      // Save to gallery
      final AssetEntity? asset = await PhotoManager.editor.saveImageWithPath(filePath, title: title);

      return asset != null;
    } catch (e) {
      debugPrint('Error saving image to photo gallery: $e');
      return false;
    }
  }

  /// Save a video to the device's photo gallery
  static Future<bool> saveVideoToGallery(String filePath) async {
    try {
      // Request permission
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        debugPrint('Permission to access photo gallery denied');
        return false;
      }

      // Save to gallery
      final AssetEntity? asset = await PhotoManager.editor.saveVideo(File(filePath), title: path.basename(filePath));

      return asset != null;
    } catch (e) {
      debugPrint('Error saving video to photo gallery: $e');
      return false;
    }
  }
}
