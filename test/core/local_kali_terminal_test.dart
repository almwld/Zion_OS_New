import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Local Kali rootfs terminal integration', () {
    test('local archive installs into the canonical native PTY rootfs path', () async {
      final config = await File('lib/core/userland/local_kali_config.dart').readAsString();
      final bootstrap = await File('lib/core/userland/local_kali_bootstrap.dart').readAsString();
      final native = await File('android/app/src/main/kotlin/com/zion/os/MainActivity.kt').readAsString();

      expect(config, contains('/data/data/com.zion.os/files/home/.zion/dists/kali/rootfs'));
      expect(bootstrap, contains('finalRootfs = ZionLocalKaliConfig.rootfs(filesDir)'));
      expect(bootstrap, contains("'distro': 'kali'"));
      expect(bootstrap, contains("'.zion-rootfs.json'"));
      expect(native, contains('File(rootfs, "bin/sh").isFile'));
    });

    test('local install validates the archive and restores executable permissions', () async {
      final bootstrap = await File('lib/core/userland/local_kali_bootstrap.dart').readAsString();

      expect(bootstrap, contains('ZionLocalKaliConfig.expectedSha256'));
      expect(bootstrap, contains('ZionLocalKaliConfig.expectedSize'));
      expect(bootstrap, contains('XZDecoder().decodeStream'));
      expect(bootstrap, contains('entry.mode & 0x1ff'));
      expect(bootstrap, contains("'/system/bin/chmod'"));
      expect(bootstrap, contains('finalRootfs.rename(backup.path)'));
    });

    test('terminal can switch to Kali using the existing native PTY instead of a pipe', () async {
      final service = await File('lib/features/terminal/terminal_service.dart').readAsString();
      final screen = await File('lib/features/terminal/terminal_screen.dart').readAsString();
      final adapter = await File('lib/features/terminal/native_pty_adapter.dart').readAsString();

      expect(service, contains('startInteractive({bool kali = false})'));
      expect(service, contains("shell = 'zion-kali'"));
      expect(service, contains('ZionLocalKaliBootstrap().install'));
      expect(service, contains('_pty.start(rows: 40, cols: 120, shell: shell)'));
      expect(screen, contains("'تشغيل/إيقاف Kali Linux'") | contains("'تبديل بيئة Kali Linux'"));
      expect(screen, contains('startInteractive(kali: launchKali)'));
      expect(adapter, contains("'shell': shell.trim()"));
    });
  });
}
