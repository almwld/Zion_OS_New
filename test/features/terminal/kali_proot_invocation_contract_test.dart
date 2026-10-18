import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kali PTY uses the native PRoot protocol and passes the bundled loader', () async {
    final dartSource = await File('lib/features/terminal/terminal_service.dart').readAsString();
    final nativeSource = await File('android/app/src/main/cpp/zion_pty.c').readAsString();

    // The display/session label (zion-kali@...) is not a native launch command.
    expect(
      dartSource,
      contains("nativeShellOverride = 'kali:\${proot.path}|\$path|\${loader.path}';"),
    );
    expect(nativeSource, contains('strncmp(configured_shell, "kali:", 5)'));
    expect(nativeSource, contains('setenv("PROOT_LOADER", kali_loader, 1)'));
    expect(nativeSource, contains('setenv("PROOT_NO_SECCOMP", "1", 1)'));
    expect(nativeSource, contains('"-w", "/"'));
  });
}
