import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/userland/zion_bootstrap.dart';

void main() {
  test('rejects an archive without a Zion manifest', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('usr/bin/readme', 4, [1, 2, 3, 4]));
    final file = File(Directory.systemTemp.path + '/zion-invalid.zip');
    await file.writeAsBytes(ZipEncoder().encode(archive)!);

    final result = await ZionBootstrap().installFromArchive(file.path);
    expect(result.success, isFalse);
    expect(result.error, contains('zion-manifest.json'));
    await file.delete();
  });

  test('rejects path traversal before extraction', () async {
    final payload = [1, 2, 3];
    final archive = Archive()
      ..addFile(ArchiveFile('../escape', payload.length, payload))
      ..addFile(ArchiveFile(
        'zion-manifest.json',
        0,
        utf8.encode(jsonEncode(<String, Object?>{
          'format': 'zion-userland-v1',
          'release': 'test',
          'files': <String, String>{
            '../escape': sha256.convert(payload).toString(),
          },
        })),
      ));
    final file = File(Directory.systemTemp.path + '/zion-traversal.zip');
    await file.writeAsBytes(ZipEncoder().encode(archive)!);

    final result = await ZionBootstrap().installFromArchive(file.path);
    expect(result.success, isFalse);
    expect(result.error, contains('مسار غير آمن'));
    await file.delete();
  });

  test('isInstalled stays false until the real marker and zion-pkg executable exist', () async {
    expect(await ZionBootstrap.isInstalled(), isFalse);
  });
}
