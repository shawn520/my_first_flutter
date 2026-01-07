import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class CryptoService {
  static const int _keyLength = 32;
  static const int _ivLength = 16;

  /// Derives a 256-bit key from password using PBKDF2-like approach
  static Uint8List deriveKey(String password, String salt) {
    final saltedPassword = '$password$salt';
    // Use multiple rounds of SHA-256 for key derivation
    List<int> hash = utf8.encode(saltedPassword);
    for (var i = 0; i < 10000; i++) {
      hash = sha256.convert(hash).bytes;
    }
    return Uint8List.fromList(hash.sublist(0, _keyLength));
  }

  /// Generates a random salt
  static String generateSalt() {
    final key = Key.fromSecureRandom(_keyLength);
    return base64.encode(key.bytes);
  }

  /// Generates a random IV
  static IV generateIV() {
    return IV.fromSecureRandom(_ivLength);
  }

  /// Encrypts data using AES-256-CBC
  static String encrypt(String plainText, Uint8List keyBytes) {
    final key = Key(keyBytes);
    final iv = generateIV();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Prepend IV to encrypted data
    final combined = iv.bytes + encrypted.bytes;
    return base64.encode(combined);
  }

  /// Decrypts data using AES-256-CBC
  static String decrypt(String encryptedText, Uint8List keyBytes) {
    final combined = base64.decode(encryptedText);
    final ivBytes = combined.sublist(0, _ivLength);
    final encryptedBytes = combined.sublist(_ivLength);

    final key = Key(keyBytes);
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    return encrypter.decrypt(
      Encrypted(Uint8List.fromList(encryptedBytes)),
      iv: iv,
    );
  }

  /// Hashes password for verification
  static String hashPassword(String password, String salt) {
    final saltedPassword = '$password$salt';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies password against stored hash
  static bool verifyPassword(String password, String salt, String storedHash) {
    final computedHash = hashPassword(password, salt);
    return computedHash == storedHash;
  }
}
