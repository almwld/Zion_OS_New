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

    test('device commands use the native Zion API channel', () async {
      final api = await File('lib/features/terminal/zion_api.dart').readAsString();
      expect(api, contains("MethodChannel('zion.os/api')"));
      expect(api, contains("_map('tts-speak'"));
      expect(api, isNot(contains('Termux API')));
      expect(await File('lib/features/terminal/termux_api.dart').exists(), isFalse);
    });

    test('native PTY does not export legacy Termux environment variables', () async {
      final source = await File('android/app/src/main/cpp/zion_pty.c').readAsString();
      expect(source, isNot(contains('TERMUX_HOME')));
      expect(source, contains('ZION_TERMINAL'));
      expect(source, isNot(contains('/system/bin/sh')));
      expect(source, isNot(contains('android-posix')));
      expect(source, contains('"-b", "/data/data/com.zion.os/files/home:/root"'));
    });

    test('terminal never silently falls back to Android host shell', () async {
      final service = await File('lib/features/terminal/terminal_service.dart').readAsString();
      final capabilities = await File('lib/features/terminal/terminal_capabilities.dart').readAsString();
      expect(service, isNot(contains("const androidShell = '/system/bin/sh'")));
      expect(service, isNot(contains("shell = '/system/bin/sh'")));
      expect(service, contains("'PREFIX': '/data/data/com.zion.os/files/usr'"));
      expect(service, contains("'LD_LIBRARY_PATH': '/data/data/com.zion.os/files/usr/lib:/data/data/com.zion.os/files/usr/lib64'"));
      expect(service, contains('environment: _userlandEnvironment'));
      expect(service, contains('_scheduleUserlandInstall()'));
      expect(capabilities, contains('NO HOST-SHELL FALLBACK'));
      expect(capabilities, isNot(contains('FALLBACK: Android /system/bin/sh')));
    });

    test('PRoot strategy drains both pipes and enforces command timeouts', () async {
      final strategy = await File('lib/core/magiczionos/strategies/proot_strategy.dart').readAsString();
      expect(strategy, contains('stdoutFuture'));
      expect(strategy, contains('stderrFuture'));
      expect(strategy, contains('timeout ?? const Duration(seconds: 30)'));
      expect(strategy, contains('workingDirectory: workingDirectory'));
    });

    test('rootfs network requests have bounded checksum and download waits', () async {
      final source = await File('lib/core/magiczionos/installers/rootfs_downloader.dart').readAsString();
      expect(source, contains('http.get(checksumUri).timeout(_checksumTimeout)'));
      expect(source, contains('client.send(request).timeout(_downloadHeaderTimeout)'));
      expect(source, contains('response.stream.timeout(_downloadIdleTimeout).pipe(sink)'));
    });

    test('Linux rootfs downloads reject unsupported app architectures', () async {
      final downloader = await File('lib/core/magiczionos/installers/rootfs_downloader.dart').readAsString();
      expect(downloader, contains('Abi.current() != Abi.androidArm64'));
      expect(downloader, contains('ARM64 فقط'));
    });

    test('Kali PTY binds Zion home into the Linux root home', () async {
      final native = await File('android/app/src/main/cpp/zion_pty.c').readAsString();
      expect(native, contains('"-b", "/storage/emulated/0"'));
      expect(native, contains('"/data/data/com.zion.os/files/home:/root"'));
    });

    test('background Userland bootstrap avoids platform-only path provider calls', () async {
      final installer = await File('lib/core/userland/zion_userland_installer.dart').readAsString();
      final bootstrap = await File('lib/core/userland/zion_bootstrap.dart').readAsString();
      expect(installer, isNot(contains('path_provider')));
      expect(installer, contains(r"Directory('${ZionBootstrap.base}/zion/bootstrap-downloads')"));
      expect(bootstrap, contains("'/system/bin/chmod'"));
      expect(bootstrap, contains('static Future<Directory?> _activate'));
      expect(bootstrap, contains('previousPrefix'));
    });

    test('Zion Pkg uses Userland libraries and never shells out for host command lookup', () async {
      final pkg = await File('lib/core/userland/zion_pkg.dart').readAsString();
      expect(pkg, contains("'LD_LIBRARY_PATH': prefix + '/lib:' + prefix + '/lib64'"));
      expect(pkg, contains("'DEBIAN_FRONTEND': 'noninteractive'"));
      expect(pkg, isNot(contains("Process.run('/system/bin/sh'")));
      expect(pkg, contains("const <String>['/system/bin', '/system/xbin']"));
    });

    test('runtime probes reject non-executable files and handle empty shared storage', () async {
      final runtime = await File('lib/features/terminal/zion_runtime_service.dart').readAsString();
      expect(runtime, contains('(stat.mode & 0x49) != 0'));
      expect(runtime, contains('await shared.list(followLinks: false).isEmpty'));
    });

    test('existing PRoot binaries are checked before being accepted', () async {
      final installer = await File('lib/core/magiczionos/installers/proot_installer.dart').readAsString();
      expect(installer, contains('await target.exists() && !force && await _isRunnable(target)'));
      expect(installer, contains("const <String>['--version']"));
      expect(installer, contains('_releaseDigest(assetName)'));
      expect(installer, contains('SHA-256'));
      expect(installer, contains("File(prefix.path + '/bin/.proot.new')"));
      expect(installer, contains('if (movedPrevious && await backup.exists())'));
    });

    test('Linux rootfs installer uses the same canonical root as Zion PRoot', () async {
      final downloader = await File('lib/core/magiczionos/installers/rootfs_downloader.dart').readAsString();
      final runtime = await File('lib/core/userland/zion_proot.dart').readAsString();
      expect(downloader, contains('ZionProot.distroRoot'));
      expect(downloader, contains("'/rootfs'"));
      expect(runtime, contains("distroRoot + '/' + distro.name + '/rootfs'"));
      expect(runtime, contains("home + ':/root'"));
      expect(runtime, contains("'--link2symlink'"));
      expect(downloader, contains("File(sourceDir.path + '/bin/sh')"));
      expect(downloader, contains('var movedPrevious = false;'));
      expect(downloader, contains('if (movedPrevious && await backup.exists())'));
    });

    test('proot-distro shell wrapper passes syntax and runs through a Zion PRoot path', () async {
      final bootstrap = await File('lib/core/userland/zion_bootstrap.dart').readAsString();
      final match = RegExp(r"""'proot-distro': r'''([\s\S]*?)''',""")
          .firstMatch(bootstrap);
      expect(match, isNotNull);
      final temp = await Directory.systemTemp.createTemp('zion-proot-cli-test-');
      try {
        final script = File('${temp.path}/proot-distro');
        await script.writeAsString(match!.group(1)!);
        final syntax = await Process.run('bash', <String>['-n', script.path]);
        expect(syntax.exitCode, 0, reason: syntax.stderr.toString());

        final home = Directory('${temp.path}/home');
        final prefix = Directory('${temp.path}/usr');
        final rootfsBin = Directory('${home.path}/.zion/dists/ubuntu/rootfs/bin');
        await rootfsBin.create(recursive: true);
        await prefix.create(recursive: true);
        final proot = File('${prefix.path}/bin/proot');
        await proot.parent.create(recursive: true);
        await proot.writeAsString('#!/bin/sh\nprintf "ZION_PROOT_TEST:%s\n" "\$@"\n');
        await File('${rootfsBin.path}/sh').writeAsString('#!/bin/sh\nexit 0\n');
        final chmod = await Process.run('chmod', <String>['+x', proot.path, '${rootfsBin.path}/sh']);
        expect(chmod.exitCode, 0, reason: chmod.stderr.toString());

        final result = await Process.run(
          'bash',
          <String>[script.path, 'login', 'ubuntu', '--', 'echo', 'zion-standalone'],
          environment: <String, String>{...Platform.environment, 'HOME': home.path, 'PREFIX': prefix.path},
        );
        expect(result.exitCode, 0, reason: result.stderr.toString());
        final output = result.stdout.toString();
        expect(output, contains('ZION_PROOT_TEST:-0'));
        expect(output, contains('zion-standalone'));
      } finally {
        await temp.delete(recursive: true);
      }
    });

    test('interactive Kali session and installer share the canonical rootfs path', () async {
      final service = await File('lib/features/terminal/terminal_service.dart').readAsString();
      final activity = await File('android/app/src/main/kotlin/com/zion/os/MainActivity.kt').readAsString();
      final loader = await File('lib/core/services/kali_loader_service.dart').readAsString();
      expect(service, contains('/home/.zion/dists/kali/rootfs'));
      expect(activity, contains('home/.zion/dists/kali/rootfs'));
      expect(loader, contains('/home/.zion/dists/kali/rootfs'));
      expect(loader, isNot(contains('/data/local/kali')));
      expect(service, contains("if (shell == 'zion-kali')"));
      expect(service, contains("'--link2symlink', '-0', '-r', rootfs"));
      expect(service, contains("'-b', '/data/data/com.zion.os/files/home:/root'"));
      expect(service, contains("'/bin/sh', '-lc', command"));
    });

    test('bootstrap fails closed when extracted file permissions cannot be applied', () async {
      final source = await File('lib/core/userland/zion_bootstrap.dart').readAsString();
      expect(source, contains("if (result.exitCode != 0)"));
      expect(source, contains("throw FileSystemException("));
      expect(source, isNot(contains("static Future<void> _chmod(String path,int mode) async {try{")));
    });

    test('bootstrap removes partial staging data after failed installation', () async {
      final source = await File('lib/core/userland/zion_bootstrap.dart').readAsString();
      final method = source.substring(
        source.indexOf('Future<BootstrapResult> installFromArchive'),
        source.indexOf('static Future<void> _dirs'),
      );
      expect(method, contains('finally {'));
      expect(method, contains('await staged.delete(recursive: true)'));
    });

    test('bootstrap exposes native Zion proot-distro and documented TTS command', () async {
      final source = await File('lib/core/userland/zion_bootstrap.dart').readAsString();
      expect(source, contains("'proot-distro': r'''"));
      expect(source, contains("'zion-api-tts': r'''"));
      expect(source, contains(r'id="zion-pkg-$(date +%s 2>/dev/null)-$$"'));
      expect(source, contains(r'PREFIX="${PREFIX:-/data/data/com.zion.os/files/usr}"'));
      expect(source, contains(r'PROOT="$PREFIX/bin/proot"'));
      expect(source, isNot(contains('/data/data/com.termux')));
    });
  });
}
