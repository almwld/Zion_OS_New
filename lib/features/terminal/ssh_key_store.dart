import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SshKeyStore {
  const SshKeyStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;
  static const _prefix = 'zion.ssh.key.';

  Future<void> savePrivateKey(String name, String privateKey) async {
    final clean = name.trim();
    if (clean.isEmpty || privateKey.trim().isEmpty) {
      throw ArgumentError('SSH key name and private key are required.');
    }
    await _storage.write(key: _prefix + clean, value: privateKey);
  }

  Future<String?> readPrivateKey(String name) =>
      _storage.read(key: _prefix + name.trim());

  Future<void> deletePrivateKey(String name) =>
      _storage.delete(key: _prefix + name.trim());

  /// Uses a real Zion/Termux ssh-keygen executable when available.
  Future<ProcessResult?> generateWithUserland({
    required String executable,
    required String outputPath,
    String type = 'ed25519',
  }) async {
    if (!await File(executable).exists()) return null;
    final parent = File(outputPath).parent;
    await parent.create(recursive: true);
    return Process.run(
      executable,
      <String>['-t', type, '-f', outputPath, '-N', ''],
      runInShell: false,
    );
  }
}
