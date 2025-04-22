import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encryption;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling AES encryption and decryption
class CryptoService {
  static const String _saltKey = 'toss_crypto_salt_key';

  // Singleton pattern
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Generate a secure random salt
  Future<Uint8List> _generateSalt({int length = 32}) async {
    debugPrint('Generating secure random salt');
    try {
      final random = Random.secure();
      final salt = Uint8List(length);
      for (var i = 0; i < length; i++) {
        salt[i] = random.nextInt(256);
      }
      debugPrint('Generated secure random salt');
      return salt;
    } catch (e) {
      debugPrint('Error generating salt: $e');
      rethrow;
    }
  }

  /// Store the salt in secure storage
  Future<void> _storeSalt(Uint8List salt) async {
    debugPrint('Storing salt in secure storage');
    try {
      final saltBase64 = base64.encode(salt);
      await _secureStorage.write(key: _saltKey, value: saltBase64);
      debugPrint('Salt stored successfully');
    } catch (e) {
      debugPrint('Error storing salt: $e');
      rethrow;
    }
  }

  /// Get the salt from secure storage or generate a new one if it doesn't exist
  Future<Uint8List> _getSalt() async {
    debugPrint('Getting salt from secure storage');
    try {
      final saltBase64 = await _secureStorage.read(key: _saltKey);
      if (saltBase64 == null || saltBase64.isEmpty) {
        debugPrint('No salt found in storage, generating a new one');
        final newSalt = await _generateSalt();
        await _storeSalt(newSalt);
        return newSalt;
      }
      debugPrint('Retrieved salt from storage');
      return Uint8List.fromList(base64.decode(saltBase64));
    } catch (e) {
      debugPrint('Error getting salt: $e');
      rethrow;
    }
  }

  /// Generate a key from a PIN using the stored salt
  Future<encryption.Key> _generateKeyFromPin(String pin, {Uint8List? providedSalt}) async {
    debugPrint('Generating key from PIN');
    try {
      // Use the provided salt or get the stored one
      final salt = providedSalt ?? await _getSalt();

      // Use PBKDF2-like approach to derive a key from the PIN
      final bytes = utf8.encode(pin);
      final digest = crypto.Hmac(crypto.sha256, salt).convert(bytes);

      // Perform multiple iterations to strengthen the key
      Uint8List result = Uint8List.fromList(digest.bytes);
      for (int i = 1; i < 10000; i++) {
        final hmac = crypto.Hmac(crypto.sha256, salt);
        final nextDigest = hmac.convert(result);
        result = Uint8List.fromList(nextDigest.bytes);
      }

      // Ensure we have exactly 32 bytes (256 bits) for AES-256
      if (result.length > 32) {
        result = result.sublist(0, 32);
      }

      return encryption.Key(result);
    } catch (e) {
      debugPrint('Error generating key from PIN: $e');
      rethrow;
    }
  }

  /// Encrypt data using AES with a PIN
  Future<String> encrypt(String data, String pin) async {
    debugPrint('Encrypting data');
    try {
      // Get or generate a salt
      final salt = await _getSalt();

      // Generate a key using the salt
      final key = await _generateKeyFromPin(pin, providedSalt: salt);
      final iv = encryption.IV.fromSecureRandom(16);
      final encrypter = encryption.Encrypter(encryption.AES(key, mode: encryption.AESMode.cbc));

      final encrypted = encrypter.encrypt(data, iv: iv);

      // Combine IV, salt, and encrypted data for transmission
      // Include version to support future format changes
      final result = {'version': 1, 'iv': base64.encode(iv.bytes), 'salt': base64.encode(salt), 'data': encrypted.base64};

      return jsonEncode(result);
    } catch (e) {
      debugPrint('Error encrypting data: $e');
      rethrow;
    }
  }

  /// Decrypt data using AES with a PIN
  Future<String> decrypt(String encryptedData, String pin) async {
    debugPrint('Decrypting data');
    try {
      // Parse the encrypted data JSON
      final encryptedJson = jsonDecode(encryptedData);

      // Validate required fields
      if (!encryptedJson.containsKey('iv') || !encryptedJson.containsKey('salt') || !encryptedJson.containsKey('data')) {
        debugPrint('Invalid encrypted data format: missing required fields');
        throw FormatException('Invalid encrypted data format: missing required fields');
      }

      final iv = encryption.IV.fromBase64(encryptedJson['iv']);
      final salt = Uint8List.fromList(base64.decode(encryptedJson['salt']));
      final encrypted = encryption.Encrypted.fromBase64(encryptedJson['data']);

      // Generate key using the salt from the encrypted data
      final key = await _generateKeyFromPin(pin, providedSalt: salt);
      final encrypter = encryption.Encrypter(encryption.AES(key, mode: encryption.AESMode.cbc));

      final decryptedData = encrypter.decrypt(encrypted, iv: iv);
      return decryptedData;
    } catch (e) {
      debugPrint('Error decrypting data: $e');
      rethrow;
    }
  }

  /// Generate a hash of the PIN for verification
  String hashPin(String pin) {
    debugPrint('Hashing PIN');
    try {
      final bytes = utf8.encode(pin);
      final digest = crypto.sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Error hashing PIN: $e');
      rethrow;
    }
  }

  /// Verify a PIN against a hash
  bool verifyPin(String pin, String hash) {
    debugPrint('Verifying PIN');
    try {
      final pinHash = hashPin(pin);
      return pinHash == hash;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }
}
