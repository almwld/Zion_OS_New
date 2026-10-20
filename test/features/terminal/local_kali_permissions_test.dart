import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/userland/local_kali_bootstrap.dart';

void main() {
  test('repairs only essential Kali runtime permissions and is repeatable', () async {
    final temp = await Directory.systemTemp.createTemp('zion-kali-permissions-');
    addTearDown(() => temp.delete(recursive: true));

    final root = Directory('${temp.path}/rootfs');
    final directories = <String>[
      root.path,
      '${root.path}/usr',
      '${root.path}/usr/bin',
      '${root.path}/usr/lib',
      '${root.path}/usr/lib/aarch64-linux-gnu',
      '${root.path}/bin',
      '${root.path}/etc',
      '${root.path}/root',
      '${root.path}/tmp',
      '${root.path}/var',
    ];
    for (final path in directories) {
      await Directory(path).create(recursive: true);
      await Process.run('chmod', <String>['700', path]);
    }

    final requiredFiles = <String>[
      '${root.path}/bin/bash',
      '${root.path}/bin/sh',
      '${root.path}/usr/bin/env',
      '${root.path}/usr/bin/dash',
      '${root.path}/usr/bin/ls',
      '${root.path}/usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1',
      '${root.path}/usr/lib/aarch64-linux-gnu/libc.so.6',
      '${root.path}/usr/lib/aarch64-linux-gnu/libtinfo.so.6.6',
      '${root.path}/usr/lib/aarch64-linux-gnu/unrelated.conf',
    ];
    for (final path in requiredFiles) {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString('fixture');
      await Process.run('chmod', <String>['600', path]);
    }

    const installer = ZionLocalKaliBootstrap();
    await installer.repairRuntimePermissions(root.path);
    await installer.repairRuntimePermissions(root.path);

    for (final path in directories) {
      final stat = await Directory(path).stat();
      expect(stat.mode & 0x1ff, 0x1ed, reason: 'directory should be 0755: $path');
    }
    for (final path in requiredFiles.take(6)) {
      final stat = await File(path).stat();
      expect(stat.mode & 0x1ff, 0x1ed, reason: 'runtime ELF should be 0755: $path');
    }
    for (final path in requiredFiles.skip(6).take(2)) {
      final stat = await File(path).stat();
      expect(stat.mode & 0x1ff, 0x1a4, reason: 'shared library should be 0644: $path');
    }
    final unrelated = await File(requiredFiles.last).stat();
    expect(unrelated.mode & 0x1ff, 0x180,
        reason: 'unrelated files must retain their original permissions');
  });
}
