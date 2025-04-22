import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Service for calculating and verifying SHA256 hashes
class HashService {
  /// Calculate SHA256 hash for a file
  Future<String> calculateFileHash(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // For large files, read in chunks to avoid memory issues
      final input = file.openRead();
      final digest = await sha256.bind(input).first;
      return digest.toString();
    } catch (e) {
      debugPrint('Error calculating file hash: $e');
      rethrow;
    }
  }

  /// Calculate SHA256 hash for bytes
  String calculateBytesHash(Uint8List bytes) {
    try {
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Error calculating bytes hash: $e');
      rethrow;
    }
  }

  /// Calculate SHA256 hash for a string
  String calculateStringHash(String text) {
    try {
      final bytes = utf8.encode(text);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Error calculating string hash: $e');
      rethrow;
    }
  }

  /// Verify if the provided hash matches the calculated hash for a file
  Future<bool> verifyFileHash(String filePath, String expectedHash) async {
    try {
      final calculatedHash = await calculateFileHash(filePath);
      return calculatedHash == expectedHash;
    } catch (e) {
      debugPrint('Error verifying file hash: $e');
      return false;
    }
  }

  /// Verify if the provided hash matches the calculated hash for bytes
  bool verifyBytesHash(Uint8List bytes, String expectedHash) {
    try {
      final calculatedHash = calculateBytesHash(bytes);
      return calculatedHash == expectedHash;
    } catch (e) {
      debugPrint('Error verifying bytes hash: $e');
      return false;
    }
  }

  /// Verify if the provided hash matches the calculated hash for a string
  bool verifyStringHash(String text, String expectedHash) {
    try {
      final calculatedHash = calculateStringHash(text);
      return calculatedHash == expectedHash;
    } catch (e) {
      debugPrint('Error verifying string hash: $e');
      return false;
    }
  }
}
