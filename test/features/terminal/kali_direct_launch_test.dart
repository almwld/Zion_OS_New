import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Direct local Kali launch', () {
    test('terminal saves a configurable rootfs path and exposes one-tap launch', () async {
      final source = await File('lib/features/terminal/terminal_screen.dart').readAsString();
      expect(source, contains('zion_terminal_kali_rootfs_path_v1'));
      expect(source, contains('/storage/emulated/0/Download/Kali'));
      expect(source, contains('_startKali()'));
      expect(source, contains('__zion_launch_kali__'));
      expect(source, contains('مسار Kali المحلي'));
    });

    test('Kali PTY profile validates the local rootfs without installing Userland', () async {
      final source = await File('lib/features/terminal/terminal_service.dart').readAsString();
      final start = source.indexOf('Future<bool> startInteractive({String? kaliRootfsPath})');
      final end = source.indexOf('void write(String input)', start);
      expect(start, greaterThanOrEqualTo(0));
      final method = source.substring(start, end);
      expect(method, contains("File('$rootfsPath/bin/bash')"));
      expect(method, contains("File('$rootfsPath/bin/sh')"));
      expect(method, contains("shell = 'zion-kali@$rootfsPath'"));
      expect(method, contains("_findShell(installIfMissing: true)"));
      expect(method.indexOf('if (kaliRootfsPath != null)'),
          lessThan(method.indexOf('_findShell(installIfMissing: true)')));
    });

    test('native PTY maps a selected absolute rootfs to PRoot in place', () async {
      final activity = await File('android/app/src/main/kotlin/com/zion/os/MainActivity.kt').readAsString();
      expect(activity, contains('shell?.startsWith("zion-kali@") == true'));
      expect(activity, contains('Launch the selected rootfs in-place. Never copy or extract it.'));
      expect(activity, contains('isValidKaliRootfs(rootfs)'));
      final native = await File('android/app/src/main/cpp/zion_pty.c').readAsString();
      expect(native, contains('exec_kali_proot'));
      expect(native, contains('"kali:"'));
    });

    test('Kali services reuse the same saved local rootfs path', () async {
      final source = await File('lib/core/services/kali_loader_service.dart').readAsString();
      expect(source, contains("static const String _localRootfsPreferenceKey = 'zion_terminal_kali_rootfs_path_v1'"));
      expect(source, contains('static Future<String?> _resolveRootfsPath()'));
      expect(source, contains("'-r', rootfsPath"));
      expect(source, contains('no copy performed'));
    });
  });
}
