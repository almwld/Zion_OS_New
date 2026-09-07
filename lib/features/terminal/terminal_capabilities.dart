/// Capability registry for the Zion OS terminal.
///
/// A capability is only reported as REAL when Zion can execute it through an
/// actual runtime primitive. Unsupported offensive capabilities are explicit
/// BLOCKED rather than simulated.
class TerminalCapability {
  const TerminalCapability({
    required this.id,
    required this.label,
    required this.status,
    required this.commandHint,
  });

  final String id;
  final String label;
  final TerminalCapabilityStatus status;
  final String commandHint;
}

enum TerminalCapabilityStatus { real, runtimeDependent, blocked }

class TerminalCapabilities {
  static const List<TerminalCapability> all = <TerminalCapability>[
    TerminalCapability(
      id: 'shell',
      label: 'POSIX shell execution',
      status: TerminalCapabilityStatus.real,
      commandHint: 'pwd, ls, id, uname -a, getprop',
    ),
    TerminalCapability(
      id: 'network-diagnostics',
      label: 'Network diagnostics',
      status: TerminalCapabilityStatus.runtimeDependent,
      commandHint: 'ping, ip, ss/netstat, traceroute, nslookup/dig',
    ),
    TerminalCapability(
      id: 'remote-ssh',
      label: 'SSH client',
      status: TerminalCapabilityStatus.runtimeDependent,
      commandHint: 'ssh user@host',
    ),
    TerminalCapability(
      id: 'remote-telnet',
      label: 'Telnet client',
      status: TerminalCapabilityStatus.runtimeDependent,
      commandHint: 'telnet host port',
    ),
    TerminalCapability(
      id: 'package-manager',
      label: 'Runtime package manager',
      status: TerminalCapabilityStatus.runtimeDependent,
      commandHint: 'pkg/apt when an authorized package manager exists',
    ),
    TerminalCapability(
      id: 'wifi-assessment',
      label: 'Wi-Fi telemetry and defensive assessment',
      status: TerminalCapabilityStatus.real,
      commandHint: 'Use the Zion Wi-Fi assessment module',
    ),
    TerminalCapability(
      id: 'history',
      label: 'Persistent command history',
      status: TerminalCapabilityStatus.real,
      commandHint: 'history',
    ),
    TerminalCapability(
      id: 'audit',
      label: 'SecurityCore terminal audit',
      status: TerminalCapabilityStatus.real,
      commandHint: 'Every executed command is audited',
    ),
    TerminalCapability(
      id: 'wifi-attacks',
      label: 'WPS/Evil-Twin/Deauth/Handshake/Cracking/PMKID/Phishing',
      status: TerminalCapabilityStatus.blocked,
      commandHint: 'Not exposed as attack automation',
    ),
    TerminalCapability(
      id: 'sql-exploitation',
      label: 'Automated SQL injection/extraction',
      status: TerminalCapabilityStatus.blocked,
      commandHint: 'Use safe detection/reporting only',
    ),
    TerminalCapability(
      id: 'credential-theft',
      label: 'Credential harvesting or phishing',
      status: TerminalCapabilityStatus.blocked,
      commandHint: 'Not exposed',
    ),
  ];

  static String describe() {
    final buffer = StringBuffer('ZION TERMINAL CAPABILITIES\n');
    for (final capability in all) {
      buffer.writeln(
        '[${capability.status.name.toUpperCase()}] '
        '${capability.id}: ${capability.label}\n'
        '  ${capability.commandHint}',
      );
    }
    return buffer.toString().trimRight();
  }
}
