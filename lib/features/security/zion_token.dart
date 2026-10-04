import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ZionToken {
  static const key = 'zion_api_token';
  static const tokenBytes = 32;
  final FlutterSecureStorage storage;
  const ZionToken({this.storage = const FlutterSecureStorage()});

  Future<String> ensure() async {
    final existing = await read();
    if (existing != null && _isValid(existing)) return existing;
    final bytes = Uint8List(tokenBytes);
    final random = Random.secure();
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    final token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await write(token);
    return token;
  }

  Future<String?> read() => storage.read(key: key);
  Future<void> write(String token) => storage.write(key: key, value: token);
  Future<void> clear() => storage.delete(key: key);
  Future<bool> valid() async => _isValid(await read());

  bool _isValid(String? value) => value != null && value.length == tokenBytes * 2;
}
