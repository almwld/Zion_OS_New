import 'termux_runtime_service.dart';

class TerminalCapabilities {
  static const List<String> blockedOffensive = <String>[
    'wifi-attack',
    'credential-theft',
    'password-cracking',
    'exploit-automation',
  ];

  static String describe() => [
    'REAL: native PTY for Zion Userland sessions',
    'REAL: VT/xterm frontend with 3,000-line scrollback',
    'PRIMARY: Zion Userland Bash/Zsh/Fish/Ash',
    'BOOTSTRAP: verified Zion Userland can be downloaded and installed on first run',
    'RUNTIME_DEPENDENT: bash/zsh/fish/ash',
    'RUNTIME_DEPENDENT: pkg/apt/dpkg',
    'RUNTIME_DEPENDENT: proot/proot-distro',
    'RUNTIME_DEPENDENT: ssh/scp/sftp/ssh-keygen',
    'RUNTIME_DEPENDENT: curl/wget/ping/DNS/network tools',
    'RUNTIME_DEPENDENT: termux-* Android API commands',
    'RUNTIME_DEPENDENT: shared storage ~/storage/*',
    'BLOCKED: offensive automation and credential theft',
  ].join('\n');

  static Future<String> describeRuntime() => const TermuxRuntimeService().describe();
}
