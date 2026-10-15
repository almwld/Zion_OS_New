import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zion Userland persistence', () {
    test('durable marker is validated by actually launching Bash', () async {
      final source = await File('lib/core/userland/zion_userland_installer.dart').readAsString();
      final start = source.indexOf('Future<bool> isInstalled({void Function(String message)? onProgress})');
      final end = source.indexOf('Future<void> _writeState(', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final method = source.substring(start, end);
      expect(method, contains('final stateFile = File(_stateFilePath)'));
      expect(method, contains("state['installed'] == true"));
      expect(method, contains("state['bashPath'] == bashPath"));
      expect(method.indexOf('await stateFile.exists()'), lessThan(method.indexOf('Process.run(')));
      expect(method, contains('if (stateIsValid) return true;'));
      expect(method, contains('await stateFile.delete();'));
      expect(method.indexOf('Process.run('), lessThan(method.indexOf('if (stateIsValid) return true;')));
      expect(method, contains('invalidating state so the local backup is recopied'));
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
