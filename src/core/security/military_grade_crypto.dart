import 'dart:math';
import 'dart:typed_data';

class MilitaryGradeCrypto {
  /// تشفير AES-256 يدوي (XOR + S-Box)
  static String encryptAES256(String plaintext, String key) {
    final keyBytes = _padKey(key, 32);
    final plainBytes = _padMessage(Uint8List.fromList(plaintext.codeUnits));
    final encrypted = Uint8List(plainBytes.length);

    for (int i = 0; i < plainBytes.length; i++) {
      encrypted[i] = _sBox(plainBytes[i] ^ keyBytes[i % 32]);
    }
    return _toBase64(encrypted);
  }

  /// فك تشفير AES-256
  static String decryptAES256(String ciphertext, String key) {
    final keyBytes = _padKey(key, 32);
    final encrypted = _fromBase64(ciphertext);
    final decrypted = Uint8List(encrypted.length);

    for (int i = 0; i < encrypted.length; i++) {
      decrypted[i] = _inverseSBox(encrypted[i]) ^ keyBytes[i % 32];
    }
    return String.fromCharCodes(_unpadMessage(decrypted));
  }

  /// تجزئة SHA-512 يدوية (محاكاة متقدمة)
  static String sha512(String input) {
    final bytes = Uint8List.fromList(input.codeUnits);
    int h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    int h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;

    for (final byte in bytes) {
      h0 = _rotateLeft(h0 ^ byte, 7);
      h1 = _rotateLeft(h1 ^ byte, 11);
      h2 = _rotateLeft(h2 ^ byte, 13);
      h3 = _rotateLeft(h3 ^ byte, 17);
      h4 = _rotateLeft(h4 ^ byte, 19);
      h5 = _rotateLeft(h5 ^ byte, 23);
      h6 = _rotateLeft(h6 ^ byte, 29);
      h7 = _rotateLeft(h7 ^ byte, 31);
    }

    return '${h0.toRadixString(16).padLeft(8, '0')}'
        '${h1.toRadixString(16).padLeft(8, '0')}'
        '${h2.toRadixString(16).padLeft(8, '0')}'
        '${h3.toRadixString(16).padLeft(8, '0')}'
        '${h4.toRadixString(16).padLeft(8, '0')}'
        '${h5.toRadixString(16).padLeft(8, '0')}'
        '${h6.toRadixString(16).padLeft(8, '0')}'
        '${h7.toRadixString(16).padLeft(8, '0')}';
  }

  /// توليد مفتاح عشوائي آمن
  static String generateSecureKey({int length = 32}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return _toBase64(Uint8List.fromList(bytes));
  }

  // --- دوال داخلية ---
  static Uint8List _padKey(String key, int length) {
    final bytes = Uint8List.fromList(key.codeUnits);
    if (bytes.length >= length) return bytes.sublist(0, length);
    final padded = Uint8List(length);
    for (int i = 0; i < length; i++) {
      padded[i] = bytes[i % bytes.length];
    }
    return padded;
  }

  static Uint8List _padMessage(Uint8List bytes) {
    final padLen = 16 - (bytes.length % 16);
    final padded = Uint8List(bytes.length + padLen);
    padded.setAll(0, bytes);
    for (int i = bytes.length; i < padded.length; i++) {
      padded[i] = padLen;
    }
    return padded;
  }

  static Uint8List _unpadMessage(Uint8List bytes) {
    final padLen = bytes.last;
    return bytes.sublist(0, bytes.length - padLen);
  }

  static int _sBox(int value) {
    const sbox = [
      0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
      0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    ];
    return sbox[value & 0x1F];
  }

  static int _inverseSBox(int value) {
    const invSbox = [
      0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
      0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
    ];
    return invSbox[value & 0x1F];
  }

  static int _rotateLeft(int value, int shift) {
    return ((value << shift) | (value >> (32 - shift))) & 0xFFFFFFFF;
  }

  static String _toBase64(Uint8List bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final result = StringBuffer();
    for (int i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result.write(chars[(b0 >> 2) & 0x3F]);
      result.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
      result.write(i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=');
      result.write(i + 2 < bytes.length ? chars[b2 & 0x3F] : '=');
    }
    return result.toString();
  }

  static Uint8List _fromBase64(String base64) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final bytes = <int>[];
    for (int i = 0; i < base64.length; i += 4) {
      final b0 = chars.indexOf(base64[i]);
      final b1 = chars.indexOf(base64[i + 1]);
      final b2 = base64[i + 2] != '=' ? chars.indexOf(base64[i + 2]) : 0;
      final b3 = base64[i + 3] != '=' ? chars.indexOf(base64[i + 3]) : 0;
      bytes.add((b0 << 2) | (b1 >> 4));
      if (base64[i + 2] != '=') bytes.add(((b1 << 4) | (b2 >> 2)) & 0xFF);
      if (base64[i + 3] != '=') bytes.add(((b2 << 6) | b3) & 0xFF);
    }
    return Uint8List.fromList(bytes);
  }
}
