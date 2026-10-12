import 'zion_runtime_service.dart';

class TerminalCapabilities {
  static const List<String> blockedOffensive = <String>[
    'wifi-attack',
    'credential-theft',
    'password-cracking',
    'exploit-automation',
  ];

  static String describe() => [
    'REAL: native PTY for Zion Userland sessions',
    'REAL: VT/xterm frontend with bounded 1,200-line scrollback',
    'PRIMARY: Zion Userland Bash/Zsh/Fish/Ash',
    'BOOTSTRAP: verified Zion Userland installer is available; setup is explicit and reports failures',
    'NO HOST-SHELL FALLBACK: terminal requires a usable Zion Userland shell or installed Kali rootfs',
    'RUNTIME_DEPENDENT: bash/zsh/fish/ash',
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
