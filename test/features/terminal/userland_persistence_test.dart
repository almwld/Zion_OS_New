import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zion Userland persistence', () {
    test('Bash presence is checked without executing it or invalidating saved state', () async {
      final source = await File('lib/core/userland/zion_userland_installer.dart').readAsString();
      final start = source.indexOf('Future<bool> isInstalled({void Function(String message)? onProgress})');
      final end = source.indexOf('Future<void> _writeState(', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final method = source.substring(start, end);
      expect(method, contains('final bashFile = File(bashPath)'));
      expect(method, contains('final stat = await bashFile.stat()'));
      expect(method, contains('stat.size >= 100000'));
      expect(method, contains('Keeping usr/ in place'));
      expect(method, isNot(contains('Process.run(')));
      expect(method, isNot(contains('stateFile.delete()')));
      expect(method, isNot(contains('clearing stale state')));
    });

    test('local Termux backup discovery covers common Android folder layouts', () async {
      final installer = await File('lib/core/userland/zion_userland_installer.dart').readAsString();
      expect(installer, contains("'/storage/emulated/0/Download/termux_usr_backup'"));
      expect(installer, contains("'/storage/emulated/0/termux_usr_backup'"));
      expect(installer, contains("'/storage/emulated/0/Download/Termux/usr'"));
      expect(installer, contains("'/storage/emulated/0/Download/termux_usr_backup/usr'"));
      expect(installer, contains("'/storage/emulated/0/ZionUniversal/usr'"));
      expect(installer, contains("'/storage/emulated/0/ZionUniversal/termux/usr'"));
      expect(installer, contains("'/storage/emulated/0/ZionUniversal/bootstrap-aarch64.zip'"));
      expect(installer, contains("'/storage/emulated/0/ZionUniversal/termux-bootstrap-aarch64.zip'"));
      expect(installer, contains("for (final candidate in backupCandidates)"));
      expect(installer, contains("if (!await Directory(candidate).exists()) continue;"));
    });

    test('new terminal sessions reuse a verified local shell before restore', () async {
      final source = await File('lib/features/terminal/terminal_service.dart').readAsString();
      final start = source.indexOf('Future<String?> _findShell(');
      final end = source.indexOf('Future<void> _ensureTerminalEnvironment()', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final method = source.substring(start, end);
      expect(method, contains('_findUsableUserlandShell()'));
      expect(method, contains('_userlandInstaller.isInstalled('));
      expect(method, contains('_userlandInstaller.installLatest('));
      expect(method.indexOf('_findUsableUserlandShell()'), lessThan(method.indexOf('_userlandInstaller.installLatest(')));
      expect(source, contains("'/data/data/com.zion.os/files/home'"));
      expect(source, contains("'/data/data/com.zion.os/files/usr'"));
    });

    test('local recovery is offline-only and leaves Android shell available', () async {
      final installer = await File('lib/core/userland/zion_userland_installer.dart').readAsString();
      final service = await File('lib/features/terminal/terminal_service.dart').readAsString();
      expect(installer, isNot(contains('_downloadFromSingleEndpoint')));
      expect(installer, contains('لم تتم محاولة الاتصال بالإنترنت'));
      expect(service, contains("const shell = '/system/bin/sh'"));
      expect(service, contains("'/system/bin/sh'"));
    });
  });
}
