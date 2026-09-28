import 'dart:convert';
import 'dart:io';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();
  
  final Random _random = Random.secure();
  
  // ============================================
  // Hashing Functions
  // ============================================
  
  String md5(String input) {
    return crypto.md5.convert(utf8.encode(input)).toString();
  }
  
  String sha1(String input) {
    return crypto.sha1.convert(utf8.encode(input)).toString();
  }
  
  String sha256(String input) {
    return crypto.sha256.convert(utf8.encode(input)).toString();
  }
  
  String sha512(String input) {
    return crypto.sha512.convert(utf8.encode(input)).toString();
  }
  
  // ============================================
  // Base64 Functions
  // ============================================
  
  String base64Encode(String input) {
    return base64.encode(utf8.encode(input));
  }
  
  String base64Decode(String input) {
    try {
      return utf8.decode(base64.decode(input));
    } catch (_) {
      return 'Invalid Base64 string';
    }
  }
  
  // ============================================
  // XOR Encryption
  // ============================================
  
  String xorEncrypt(String text, String key) {
    final result = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final charCode = text.codeUnitAt(i) ^ key.codeUnitAt(i % key.length);
      result.write(String.fromCharCode(charCode));
    }
    return base64.encode(utf8.encode(result.toString()));
  }
  
  String xorDecrypt(String encrypted, String key) {
    try {
      final decoded = utf8.decode(base64.decode(encrypted));
      final result = StringBuffer();
      for (var i = 0; i < decoded.length; i++) {
        final charCode = decoded.codeUnitAt(i) ^ key.codeUnitAt(i % key.length);
        result.write(String.fromCharCode(charCode));
      }
      return result.toString();
    } catch (_) {
      return 'Decryption failed';
    }
  }
  
  // ============================================
  // Caesar Cipher
  // ============================================
  
  String caesarEncrypt(String text, int shift) {
    final result = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char.toUpperCase() != char.toLowerCase()) {
        final base = char.toUpperCase() == char ? 65 : 97;
        final shifted = (char.codeUnitAt(0) - base + shift) % 26 + base;
        result.write(String.fromCharCode(shifted));
      } else {
        result.write(char);
      }
    }
    return result.toString();
  }
  
  String caesarDecrypt(String text, int shift) {
    return caesarEncrypt(text, 26 - (shift % 26));
  }
  
  // ============================================
  // Reverse String
  // ============================================
  
  String reverse(String text) {
    return String.fromCharCodes(text.codeUnits.reversed);
  }
  
  // ============================================
  // Generate Random Strings
  // ============================================
  
  String generateRandomString(int length, {bool includeNumbers = true, bool includeSpecial = false}) {
    const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()_+-=[]{};:<>?';
    
    var charset = letters;
    if (includeNumbers) charset += numbers;
    if (includeSpecial) charset += special;
    
    return String.fromCharCodes(
      List.generate(length, (_) => charset.codeUnitAt(_random.nextInt(charset.length)))
    );
  }
  
  String generateSecurePassword({int length = 12}) {
    return generateRandomString(length, includeNumbers: true, includeSpecial: true);
  }
  
  // ============================================
  // Hash File (Future implementation)
  // ============================================
  
  Future<String> hashFile(String path, String algorithm) async {
    final normalized = algorithm.trim().toLowerCase().replaceAll('-', '');
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }

    crypto.Hash selectHash(String name) {
      switch (name) {
        case 'md5':
          return crypto.md5;
        case 'sha1':
          return crypto.sha1;
        case 'sha256':
          return crypto.sha256;
        case 'sha512':
          return crypto.sha512;
        default:
          throw ArgumentError.value(
            algorithm,
            'algorithm',
            'Supported algorithms: md5, sha1, sha256, sha512',
          );
      }
    }

    final digest = await selectHash(normalized).bind(file.openRead());
    return digest.toString();
  }
}
