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
      expect(method, contains('final bashRealFile = File'));
      expect(method, contains('for (final candidate in <File>[bashRealFile, bashFile])'));
      expect(method, contains('final stat = await candidate.stat()'));
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

    test('Bash ELF payload is accepted when bin/bash is a small linker wrapper', () async {
      final installer = await File('lib/core/userland/zion_userland_installer.dart').readAsString();
      final start = installer.indexOf('Future<bool> _hasCompatibleShell()');
      final end = installer.indexOf('Future<bool> _hasCompatibleProot()', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final method = installer.substring(start, end);
      expect(method, contains('/bin/bash.real'));
      expect(method, contains("path.endsWith('/bash.real') || path.endsWith('/bash')"));
      expect(method, contains('? 100000'));
    });

    test('native PTY Bash launcher inherits Zion runtime environment before linker64', () async {
      final source = await File('android/app/src/main/cpp/zion_pty.c').readAsString();
      final environmentStart = source.indexOf('static void prepare_environment(');
      final environmentEnd = source.indexOf('static int is_allowed_shell(', environmentStart);
      expect(environmentStart, greaterThanOrEqualTo(0));
      expect(environmentEnd, greaterThan(environmentStart));
      final environment = source.substring(environmentStart, environmentEnd);
      expect(environment, contains('setenv("LD_LIBRARY_PATH", full_library_path, 1)'));
      expect(environment, contains('/data/data/com.zion.os/files/usr/lib:/data/data/com.zion.os/files/usr/lib64'));
      expect(environment, contains('/data/data/com.zion.os/files/usr/libexec'));
      expect(environment, contains('setenv("SHELL", "/data/data/com.zion.os/files/usr/bin/bash", 1)'));
      expect(environment, contains('setenv("COLORTERM", "truecolor", 1)'));
      expect(environment, contains('setenv("TERMINFO", "/data/data/com.zion.os/files/usr/share/terminfo", 1)'));
      expect(environment, contains('setenv("BASH_ENV", "/data/data/com.zion.os/files/usr/etc/zion-bashrc", 1)'));
      final launcherStart = source.indexOf('static void exec_selected_shell(');
      final launcherEnd = source.indexOf('JNIEXPORT jboolean JNICALL', launcherStart);
      expect(launcherStart, greaterThanOrEqualTo(0));
      expect(launcherEnd, greaterThan(launcherStart));
      final launcher = source.substring(launcherStart, launcherEnd);
      expect(launcher, contains('execl("/system/bin/linker64", "linker64", bash_real'));
      expect(launcher, contains('"--init-file", bashrc, "-i"'));
      expect(launcher, isNot(contains('exec /system/bin/linker64')));
    });

    test('native PTY executes the selected Android system shell instead of exiting', () async {
      final source = await File('android/app/src/main/cpp/zion_pty.c').readAsString();
      final start = source.indexOf('static void exec_selected_shell(');
      final end = source.indexOf('JNIEXPORT jboolean JNICALL', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final launcher = source.substring(start, end);
      expect(launcher, contains('if (strcmp(selected, "/system/bin/sh") == 0)'));
      expect(launcher, contains('execl("/system/bin/sh", "sh", "-i", (char *)NULL)'));
    });

    test('shared-storage Userland restore retries through SAF after raw reads fail', () async {
      final installer = await File('lib/core/userland/zion_userland_installer.dart').readAsString();
      final native = await File('android/app/src/main/kotlin/com/zion/os/MainActivity.kt').readAsString();
      expect(installer, contains('_restoreUserlandFromDocumentTree'));
      expect(installer, contains("invokeMethod<Map<dynamic, dynamic>>('pickTree')"));
      expect(installer, contains("'copyDocumentToPrivate'"));
      expect(installer, contains('_installFromDirectory(staging.path'));
      expect(native, contains('DocumentsContract.getDocumentId(tree)'));
    });

    test('bootstrap ZIP discovery validates payload instead of relying on a fixed ELF offset', () async {
      final source = await File('android/app/src/main/kotlin/com/zion/os/TermuxBootstrapInstaller.kt').readAsString();
      expect(source, contains('BOOTSTRAP_BLOB_OFFSET.toInt()'));
      expect(source, contains('isBootstrapZipStream'));
      expect(source, contains('No valid bootstrap ZIP stream found in ELF'));
      expect(source, contains('TermuxInstaller.getZip()'));
    });

    test('native PTY lifecycle uses generation handles, safe initialization and bounded writes', () async {
      final native = await File('android/app/src/main/cpp/zion_pty.c').readAsString();
      final activity = await File('android/app/src/main/kotlin/com/zion/os/MainActivity.kt').readAsString();
      final adapter = await File('lib/features/terminal/native_pty_adapter.dart').readAsString();
      expect(native, contains('pthread_once(&g_sessions_once, init_sessions_once)'));
      expect(native, contains('session->generation != generation'));
      expect(native, contains('make_session_handle(slot, generation)'));
      expect(native, contains('attempt < 10'));
      expect(native, contains('5000 - (int)elapsed_ms'));
      expect(native, contains('Java_com_zion_os_MainActivity_nativeSetPaths'));
      expect(activity, contains('nativeSetPaths(filesDir.absolutePath)'));
      expect(activity, contains('nativeWritePty(handle, input).coerceIn(0, input.size)'));
      expect(adapter, contains("invokeMethod<int>('write'"));
      expect(adapter, contains('Write incomplete:'));
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
