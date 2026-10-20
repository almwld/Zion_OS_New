import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kali PRoot starts at guest root and changes to /root after tracing starts', () async {
    final source = await File('android/app/src/main/cpp/zion_pty.c').readAsString();

    // Inspect the native launcher source, not equality against the source file.
    expect(source, contains('"-w", "/"'));
    expect(
      source,
      contains("cd /root || { echo 'ZION_PROOT_CHDIR_ROOT_FAILED'; exit 125; }; exec /bin/bash --login"),
    );
    expect(source, contains('"--noprofile", "--norc", "-c"'));
  });
}
