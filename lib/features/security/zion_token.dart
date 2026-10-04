import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ZionToken {
  static const key = 'zion_api_token';
  final FlutterSecureStorage storage;
  const ZionToken({this.storage = const FlutterSecureStorage()});
  Future<String?> read() => storage.read(key: key);
  Future<void> write(String token) => storage.write(key: key, value: token);
  Future<void> clear() => storage.delete(key: key);
  Future<bool> valid() async => (await read())?.length == 64;
}
