import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'vault_crypto.dart';

class VaultService {
  final FlutterSecureStorage storage;
  const VaultService({this.storage = const FlutterSecureStorage()});

  String _key(String name) => 'zion.vault.$name';

  Future<void> put(String name, String value, String secret) async {
    if (name.trim().isEmpty) throw ArgumentError.value(name, 'name');
    await storage.write(key: _key(name), value: await VaultCrypto.protect(value, secret));
  }

  Future<String?> get(String name, String secret) async {
    final value = await storage.read(key: _key(name));
    return value == null ? null : VaultCrypto.unprotect(value, secret);
  }

  Future<List<String>> list() async {
    final all = await storage.readAll();
    return all.keys
        .where((key) => key.startsWith('zion.vault.'))
        .map((key) => key.substring('zion.vault.'.length))
        .where((name) => name.isNotEmpty)
        .toList()
      ..sort();
  }

  Future<void> remove(String name) => storage.delete(key: _key(name));
}
