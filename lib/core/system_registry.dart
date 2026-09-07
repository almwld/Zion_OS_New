class SystemRegistry {
  /// Production registry contains defensive, analytical and observability modules only.
  /// Offensive execution, credential attacks, exploitation, persistence, evasion,
  /// botnet and autonomous propagation modules are intentionally excluded.
  static const Map<String, String> _systems = {
    'ids': 'ultimate_ids_system.dart',
    'forensics': 'ultimate_forensics_system.dart',
    'crypto': 'ultimate_crypto_system.dart',
    'osint': 'ultimate_osint_system.dart',
    'threat_intel': 'ultimate_threat_intel_system.dart',
    'incident_response': 'ultimate_incident_response_system.dart',
  };

  static List<String> getAllSystems() => _systems.keys.toList(growable: false);

  static String? getSystemFile(String name) => _systems[name];

  static int get totalSystems => _systems.length;
}
