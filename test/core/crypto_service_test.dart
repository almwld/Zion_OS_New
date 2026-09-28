import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/services/crypto_service.dart';

void main() {
  test('hashFile returns the real SHA-256 digest', () async {
    final file = File('${String.fromCharCode(36)}{Directory.systemTemp.path}/zion_crypto_test.txt');
    await file.writeAsString('zion-test');
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });

    final service = CryptoService();
    final digest = await service.hashFile(file.path, 'sha-256');
    expect(digest, service.sha256('zion-test'));
  });
}
