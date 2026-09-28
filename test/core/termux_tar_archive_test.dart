import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/userland/termux_importer/termux_tar_archive.dart';

void main() {
  test('reads Termux dpkg status from tar', () async {
    final archive = Archive();
    archive.addFile(ArchiveFile.string('data/data/com.termux/files/var/lib/dpkg/status', 'Package: bash\nVersion: 5.2\nArchitecture: arm64\nStatus: install ok installed\n'));
    final bytes = TarEncoder().encodeBytes(archive);
    final dir = await Directory.systemTemp.createTemp('zion-tar-test-');
    final file = File(dir.path + '/termux.tar')..writeAsBytesSync(bytes);
    try { final result = await TermuxTarArchive.open(file.path); expect(result.success, isTrue); expect(result.statusContent, contains('Package: bash')); } finally { await dir.delete(recursive: true); }
  });
  test('rejects tar without dpkg status', () async {
    final archive = Archive(); archive.addFile(ArchiveFile.string('usr/bin/demo', 'demo'));
    final bytes = TarEncoder().encodeBytes(archive);
    final dir = await Directory.systemTemp.createTemp('zion-tar-test-');
    final file = File(dir.path + '/termux.tar')..writeAsBytesSync(bytes);
    try { final result = await TermuxTarArchive.open(file.path); expect(result.success, isFalse); expect(result.message, startsWith('UNAVAILABLE:')); } finally { await dir.delete(recursive: true); }
  });
}