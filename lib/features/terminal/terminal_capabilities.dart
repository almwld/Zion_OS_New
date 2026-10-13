import 'zion_runtime_service.dart';

class TerminalCapabilities {
  static const List<String> blockedOffensive = <String>[
    'wifi-attack',
    'credential-theft',
    'password-cracking',
    'exploit-automation',
  ];

  static String describe() => [
    'REAL: native PTY for Android /system/bin/sh',
    'REAL: VT/xterm frontend with bounded 1,200-line scrollback',
    'PRIMARY: Android system POSIX shell (/system/bin/sh)',
    'NO BOOTSTRAP REQUIRED: terminal commands use the Android OS image directly',
    'HOST SHELL IS PRIMARY: no Zion Userland or Kali rootfs required for basic commands',
    'ANDROID-IMAGE-DEPENDENT: toybox applets and vendor-provided commands',
    'RUNTIME_DEPENDENT: zion-pkg in Userland; apt/dpkg only inside an installed Linux rootfs',
    'RUNTIME_DEPENDENT: proot/proot-distro',
    'RUNTIME_DEPENDENT: ssh/scp/sftp/ssh-keygen',
    'RUNTIME_DEPENDENT: curl/wget/ping/DNS/network tools',
    'ZION_API: Android-native device commands through Zion API',
    'RUNTIME_DEPENDENT: shared storage ~/storage/*',
    'BLOCKED: offensive automation and credential theft',
  ].join('\n');

  static Future<String> describeRuntime() => const ZionRuntimeService().describe();
}
