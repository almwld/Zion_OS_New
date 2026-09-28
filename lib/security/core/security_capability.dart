/// Describes whether a security capability is available on the current
/// platform without pretending that an unavailable native facility worked.
enum CapabilityAvailability { available, unavailable, simulation }

class SecurityCapability {
  const SecurityCapability({
    required this.id,
    required this.availability,
    this.reason,
  });

  final String id;
  final CapabilityAvailability availability;
  final String? reason;

  bool get isAvailable => availability == CapabilityAvailability.available;
  bool get isSimulation => availability == CapabilityAvailability.simulation;
  bool get isUnavailable => availability == CapabilityAvailability.unavailable;
}

/// Registry used by scanners and platform adapters before invoking native
/// functionality. Feature code should degrade to UNAVAILABLE rather than
/// fabricate operational telemetry.
class SecurityCapabilityRegistry {
  SecurityCapabilityRegistry({Map<String, SecurityCapability>? capabilities})
      : _capabilities = Map.unmodifiable(
          capabilities ?? const <String, SecurityCapability>{},
        );

  final Map<String, SecurityCapability> _capabilities;

  SecurityCapability resolve(String id) {
    return _capabilities[id] ??
        SecurityCapability(
          id: id,
          availability: CapabilityAvailability.unavailable,
          reason: 'Capability has no registered platform adapter.',
        );
  }

  List<SecurityCapability> get all => _capabilities.values.toList(growable: false);
}
