import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Direct local Kali launch', () {
    test('terminal saves a configurable rootfs path and exposes one-tap launch', () async {
      final source = await File('lib/features/terminal/terminal_screen.dart').readAsString();
      expect(source, contains('zion_terminal_kali_rootfs_path_v1'));
      expect(source, contains('/storage/emulated/0/Download/Kali'));
      expect(source, contains('_startKaliFromLocalRootfs'));
      expect(source, contains('تشغيل Kali المحلي'));
    });

    test('Kali PTY profile validates the local rootfs without installing Userland', () async {
      final source = await File('lib/features/terminal/terminal_service.dart').readAsString();
      final start = source.indexOf('Future<bool> startInteractive({String? kaliRootfsPath})');
      final end = source.indexOf('void write(String input)', start);
      expect(start, greaterThanOrEqualTo(0));
      final method = source.substring(start, end);
      expect(method, contains(r"File('$path/bin/bash')"));
      expect(method, contains(r"File('$path/bin/sh')"));
      expect(method, contains(r"shell = 'zion-kali@$path'"));
      expect(method, contains("_findShell(installIfMissing: true)"));
      expect(method.indexOf('if (kaliRootfsPath != null)'),
          lessThan(method.indexOf('_findShell(installIfMissing: true)')));
    });

    test('native PTY maps a selected absolute rootfs to PRoot in place', () async {
      final activity = await File('android/app/src/main/kotlin/com/zion/os/MainActivity.kt').readAsString();
      expect(activity, contains('shell?.startsWith("zion-kali@") == true'));
      expect(activity, contains('shell?.startsWith("zion-kali@") == true'));
      expect(activity, contains('validRootfs(rootfs)'));
      final native = await File('android/app/src/main/cpp/zion_pty.c').readAsString();
      expect(native, contains('exec_kali_proot'));
      expect(native, contains('"kali:"'));
    });

    test('native Kali launch uses linker64, app-private PRoot temp, and guest loader binds', () async {
      final native = await File('android/app/src/main/cpp/zion_pty.c').readAsString();
      expect(native, contains('setenv("PROOT_TMP_DIR", "/data/data/com.zion.os/files/tmp/proot", 1)'));
      expect(native, contains('setenv("PROOT_NO_SECCOMP", "1", 1)'));
      expect(native, contains('execl("/system/bin/linker64", "linker64", proot'));
      expect(native, contains('lib/aarch64-linux-gnu:/lib/aarch64-linux-gnu'));
      expect(native, contains('usr/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu'));
      expect(native, isNot(contains('PROOT_TMP_DIR", "/storage/emulated/0')));
    });

    test('bootstrap installer validates local PRoot libraries before copying', () async {
      final installer = await File(
        'android/app/src/main/kotlin/com/zion/os/TermuxBootstrapInstaller.kt',
      ).readAsString();
      expect(installer, contains('private fun installProotLibs(prefix: File)'));
      expect(installer, contains('libtalloc.so.2'));
      expect(installer, contains('libandroid-shmem.so'));
      expect(installer, contains('validArm64Library(staged)'));
    });

    test('Kali services reuse the same saved local rootfs path', () async {
      final source = await File('lib/core/services/kali_loader_service.dart').readAsString();
      expect(source, contains("static const String _localRootfsPreferenceKey = 'zion_terminal_kali_rootfs_path_v1'"));
      expect(source, contains('static Future<String?> _resolveRootfsPath()'));
      expect(source, contains("'-r', rootfsPath"));
      expect(source, contains('no copy performed'));
      expect(source, contains('rootfsPath == _installPath && await hasChroot()'));
    });
  });
}
