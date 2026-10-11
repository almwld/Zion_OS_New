import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zion Terminal independence', () {
    test('agent process PATH contains Zion paths and no Termux installation path', () async {
      final source = await File('lib/agent/environments/environment_manager.dart').readAsString();
      expect(source, contains('/data/data/com.zion.os/files/usr/bin'));
      expect(source, isNot(contains('/data/data/com.termux')));
    });

    test('legacy terminal entry point delegates to the native PTY terminal', () async {
      final source = await File('lib/screens/apps/terminal_app.dart').readAsString();
      expect(source, contains('TerminalScreen'));
      expect(source, isNot(contains('Process.run')));
      expect(source, isNot(contains('/data/data/com.termux')));
    });

    test('PRoot resolver has no external terminal-app or host install paths', () async {
      final source = await File('lib/core/services/kali_loader_service.dart').readAsString();
      expect(source, isNot(contains('/data/data/com.termux')));
      expect(source, contains('/data/data/com.zion.os/files/usr/bin/proot'));
    });

    test('native PTY does not export legacy Termux environment variables', () async {
      final source = await File('android/app/src/main/cpp/zion_pty.c').readAsString();
      expect(source, isNot(contains('TERMUX_HOME')));
      expect(source, contains('ZION_TERMINAL'));
    });

    test('Linux rootfs installer uses the same canonical root as Zion PRoot', () async {
      final downloader = await File('lib/core/magiczionos/installers/rootfs_downloader.dart').readAsString();
      final runtime = await File('lib/core/userland/zion_proot.dart').readAsString();
      expect(downloader, contains('ZionProot.distroRoot'));
      expect(downloader, contains("'/rootfs'"));
      expect(runtime, contains("distroRoot + '/' + distro.name + '/rootfs'"));
    });

    test('interactive Kali session and installer share the canonical rootfs path', () async {
      final service = await File('lib/features/terminal/terminal_service.dart').readAsString();
      final activity = await File('android/app/src/main/kotlin/com/zion/os/MainActivity.kt').readAsString();
      final loader = await File('lib/core/services/kali_loader_service.dart').readAsString();
      expect(service, contains('/home/.zion/dists/kali/rootfs'));
      expect(activity, contains('home/.zion/dists/kali/rootfs'));
      expect(loader, contains('/home/.zion/dists/kali/rootfs'));
      expect(loader, isNot(contains('/data/local/kali')));
    });

    test('bootstrap exposes native Zion proot-distro and documented TTS command', () async {
      final source = await File('lib/core/userland/zion_bootstrap.dart').readAsString();
      expect(source, contains("'proot-distro': r'''"));
      expect(source, contains("'zion-api-tts': r'''"));
      expect(source, contains('/data/data/com.zion.os/files/usr/bin/proot'));
      expect(source, isNot(contains('/data/data/com.termux')));
    });
  });
}
