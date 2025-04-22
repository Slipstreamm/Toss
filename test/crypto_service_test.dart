import 'package:flutter_test/flutter_test.dart';
import 'package:toss/services/crypto_service.dart';

void main() {
  group('CryptoService', () {
    final cryptoService = CryptoService();
    
    test('encrypt and decrypt text data', () async {
      // Test data
      const originalText = 'This is a test message for encryption';
      const pin = '123456';
      
      // Encrypt the data
      final encryptedData = await cryptoService.encrypt(originalText, pin);
      
      // Verify encrypted data is not the same as original
      expect(encryptedData, isNot(equals(originalText)));
      
      // Decrypt the data
      final decryptedData = await cryptoService.decrypt(encryptedData, pin);
      
      // Verify decrypted data matches original
      expect(decryptedData, equals(originalText));
    });
    
    test('decrypt fails with wrong PIN', () async {
      // Test data
      const originalText = 'This is a test message for encryption';
      const correctPin = '123456';
      const wrongPin = '654321';
      
      // Encrypt with correct PIN
      final encryptedData = await cryptoService.encrypt(originalText, correctPin);
      
      // Attempt to decrypt with wrong PIN should throw an exception
      expect(() async => await cryptoService.decrypt(encryptedData, wrongPin), 
          throwsA(isA<Exception>()));
    });
  });
}
