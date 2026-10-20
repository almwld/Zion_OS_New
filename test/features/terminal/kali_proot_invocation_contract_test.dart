import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kali resolves its PRoot loader from Android nativeLibraryDir', () async {
    final terminal = await File('lib/features/terminal/terminal_service.dart').readAsString();
    final activity = await File('android/app/src/main/kotlin/com/zion/os/MainActivity.kt').readAsString();
    final native = await File('android/app/src/main/cpp/zion_pty.c').readAsString();

    // Dart passes the distro marker; Kotlin resolves the packaged loader and
    // then forwards the validated native PRoot protocol to the native PTY.
    expect(terminal, contains("shell = 'zion-kali@\$path';"));
    expect(terminal, isNot(contains("usr/libexec/proot")));
    expect(activity, contains('File(applicationInfo.nativeLibraryDir, "libproot-loader.so")'));
    expect(activity, contains('val prootReady = install(proot, 64 * 1024L, false)'));
    expect(activity, contains('shell?.startsWith("zion-kali@") == true'));
    expect(native, contains('setenv("PROOT_LOADER", kali_loader, 1)'));
    expect(native, contains('"--link2symlink", "-0", "-r", rootfs'));
  });

  test('Kali runtime permissions are repaired narrowly before validation', () async {
    final terminal = await File('lib/features/terminal/terminal_service.dart').readAsString();
    final bootstrap = await File('lib/core/userland/local_kali_bootstrap.dart').readAsString();

    expect(terminal, contains('repairRuntimePermissions(path)'));
    expect(bootstrap, contains("await applyMode('755', directories, dirs: true)"));
    expect(bootstrap, contains("await applyMode('755', executables, dirs: false)"));
    expect(bootstrap, contains("await applyMode('644', libraries, dirs: false)"));
    expect(bootstrap, contains('avoids recursively chmodding the'));
  });

  test('Userland startup reuses an existing launcher instead of restoring each tab', () async {
    final service = await File('lib/features/terminal/terminal_service.dart').readAsString();
    final installer = await File('android/app/src/main/kotlin/com/zion/os/TermuxBootstrapInstaller.kt').readAsString();

    expect(service, contains('static bool _runtimeDiagnosticsCollected = false;'));
    expect(service, contains('no reinstall will be attempted'));
    expect(installer, contains('val alreadyZionLauncher = try'));
    expect(installer, contains('if (!alreadyZionLauncher)'));
  });
}
