enum CapabilityState { available, permissionRequired, notConfigured, unavailable }

class CapabilityStatus {
  final String id;
  final String name;
  final CapabilityState state;
  final String description;

  const CapabilityStatus({
    required this.id,
    required this.name,
    required this.state,
    required this.description,
  });

  bool get isUsable => state == CapabilityState.available;
}

/// Single source of truth for runtime capability reporting.
/// Unsupported Android privileges are reported honestly instead of simulated.
class CapabilityRegistry {
  static const capabilities = <CapabilityStatus>[
    CapabilityStatus(
      id: 'neural_analyzer',
      name: 'Neural Analyzer',
      state: CapabilityState.available,
      description: 'Local command risk classification and safe suggestions.',
    ),
    CapabilityStatus(
      id: 'command_predictor',
      name: 'Command Predictor',
      state: CapabilityState.available,
      description: 'Local next-command suggestions from in-memory history.',
    ),
    CapabilityStatus(
      id: 'adaptive_interface',
      name: 'Adaptive Interface',
      state: CapabilityState.available,
      description: 'Presentation mode changes without granting privileges.',
    ),
    CapabilityStatus(
      id: 'spider_radar',
      name: 'Spider Radar',
      state: CapabilityState.available,
      description: 'Visualizes supplied discovery telemetry without fake nodes.',
    ),
    CapabilityStatus(
      id: 'voice_navigation',
      name: 'Voice Navigation',
      state: CapabilityState.available,
      description: 'Safe voice navigation and device-information actions.',
    ),
    CapabilityStatus(
      id: 'app_snapshot',
      name: 'App Snapshot',
      state: CapabilityState.available,
      description: 'Snapshots app-private documents data only.',
    ),
    CapabilityStatus(
      id: 'root_access',
      name: 'Root Access',
      state: CapabilityState.unavailable,
      description: 'A normal Flutter application cannot grant Android root.',
    ),
    CapabilityStatus(
      id: 'system_server',
      name: 'Android System Server',
      state: CapabilityState.unavailable,
      description: 'Requires an Android system component, not an app privilege.',
    ),
    CapabilityStatus(
      id: 'remote_command_execution',
      name: 'Remote Command Execution',
      state: CapabilityState.unavailable,
      description: 'Disabled; telemetry exchange must not execute arbitrary remote commands.',
    ),
  ];

  static CapabilityStatus byId(String id) => capabilities.firstWhere(
        (item) => item.id == id,
        orElse: () => const CapabilityStatus(
          id: 'unknown',
          name: 'Unknown',
          state: CapabilityState.unavailable,
          description: 'Capability is not registered.',
        ),
      );
}
