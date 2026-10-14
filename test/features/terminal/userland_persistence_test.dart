import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zion Userland persistence', () {
    test('durable install marker is checked independently of process memory', () async {
      final source = await File(
        'lib/core/userland/zion_userland_installer.dart',
      ).readAsString();
      final start = source.indexOf(
        'Future<bool> isInstalled({void Function(String message)? onProgress})',
      );
      final end = source.indexOf('Future<void> _writeState(', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final method = source.substring(start, end);

      expect(method, contains('final stateFile = File(_stateFilePath)'));
      expect(method, contains("state['installed'] == true"));
      expect(method, contains("state['bashPath'] == bashPath"));
      expect(method, isNot(contains('if (_installCompleted)')));
      expect(
        method.indexOf('await stateFile.exists()'),
        lessThan(method.indexOf('Process.run(')),
        reason: 'A persisted install must be reused before attempting to launch Bash.',
      );
    });

    test('each new terminal checks the shared installation before installing', () async {
      final source = await File(
        'lib/features/terminal/terminal_service.dart',
      ).readAsString();
      final start = source.indexOf('Future<String?> _findShell(');
      final end = source.indexOf('Future<void> _ensureTerminalEnvironment()', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final method = source.substring(start, end);

      expect(method, contains('_userlandInstaller.isInstalled('));
      expect(method, contains('_userlandInstaller.installLatest('));
      expect(
        method.indexOf('_userlandInstaller.isInstalled('),
        lessThan(method.indexOf('_userlandInstaller.installLatest(')),
      );
      expect(method, contains('_userlandBash'));
      expect(source, contains("'/data/data/com.zion.os/files/home'"));
      expect(source, contains("'/data/data/com.zion.os/files/usr'"));
    });

    test('Userland state is stored outside transient terminal-tab state', () async {
      final source = await File(
        'lib/core/userland/zion_userland_installer.dart',
      ).readAsString();
      expect(
        source,
        contains("'/data/data/com.zion.os/.userland_state.json'"),
      );
      expect(source, contains("'bashPath': '"));
      expect(source, contains('ZionBootstrap.prefix'));
    });
  });
}
