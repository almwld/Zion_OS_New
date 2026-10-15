import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Local Kali rootfs terminal integration', () {
    test('archive extraction targets the canonical PTY rootfs and stages safely', () async {
      final config = await File('lib/core/userland/local_kali_config.dart').readAsString();
      final bootstrap = await File('lib/core/userland/local_kali_bootstrap.dart').readAsString();
      final native = await File('android/app/src/main/kotlin/com/zion/os/MainActivity.kt').readAsString();

      expect(config, contains('/home/.zion/dists/kali/rootfs'));
      expect(config, contains('expectedSize = 137313840'));
      expect(bootstrap, contains('targetRootfs = ZionLocalKaliConfig.rootfs(filesDir)'));
      expect(bootstrap, contains("targetRootfs.path + '.staging-'")); 
      expect(bootstrap, contains('ZionLocalKaliConfig.expectedSha256'));
      expect(bootstrap, contains("'rootfs_path': 'home/.zion/dists/kali/rootfs'"));
      expect(native, contains('shell?.startsWith("zion-kali@") == true'));
      expect(native, contains('validRootfs(rootfs)'));
    });

    test('Super Agent auto-imports the verified local archive when Kali is requested', () async {
      final service = await File('lib/features/terminal/terminal_service.dart').readAsString();
      expect(service, contains("import '../../core/userland/local_kali_bootstrap.dart';"));
      expect(service, contains('const ZionLocalKaliBootstrap()'));
      expect(service, contains('kaliBootstrap.findLocalPackage()'));
      expect(service, contains('kaliBootstrap.install('));
      expect(service, contains('Local archive found; installing into the separate Kali rootfs'));
      expect(service, contains("const installedRootfs = '/data/data/com.zion.os/files/home/.zion/dists/kali/rootfs'"));
    });

    test('terminal launches selected local rootfs through native PTY without copying it', () async {
      final service = await File('lib/features/terminal/terminal_service.dart').readAsString();
      final screen = await File('lib/features/terminal/terminal_screen.dart').readAsString();
      final adapter = await File('lib/features/terminal/native_pty_adapter.dart').readAsString();

      expect(service, contains('startInteractive({String? kaliRootfsPath})'));
      expect(service, contains("shell = 'zion-kali@\$path'"));
      expect(service, contains("File('\$path/bin/bash')"));
      expect(service, contains("File('\$path/bin/sh')"));
      expect(screen, contains('_installKaliFromLocalArchive'));
      expect(screen, contains('startInteractive(kaliRootfsPath: path)'));
      expect(adapter, contains("'shell': shell.trim()"));
    });
  });
}
