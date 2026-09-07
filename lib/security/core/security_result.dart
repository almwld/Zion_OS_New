/// Trust boundary for every security observation produced by Zion OS.
///
/// A result is explicitly classified so simulated/lab output can never be
/// mistaken for telemetry collected from a real device or network.
enum ResultSource { real, simulated, imported, derived, unavailable }

enum SecuritySeverity { info, low, medium, high, critical }

class SecurityResult {
  const SecurityResult({
    required this.id,
    required this.timestamp,
    required this.source,
    required this.severity,
    required this.title,
    required this.description,
    this.target,
    this.confidence = 0,
    this.evidence = const <String>[],
    this.remediation,
    this.metadata = const <String, Object?>{},
  }) : assert(confidence >= 0 && confidence <= 1);

  final String id;
  final DateTime timestamp;
  final ResultSource source;
  final SecuritySeverity severity;
  final String title;
  final String description;
  final String? target;
  final double confidence;
  final List<String> evidence;
  final String? remediation;
  final Map<String, Object?> metadata;

  bool get isSimulation => source == ResultSource.simulated;
  bool get isOperational => source == ResultSource.real;

  SecurityResult copyWith({
    ResultSource? source,
    SecuritySeverity? severity,
    String? title,
    String? description,
    String? target,
    double? confidence,
    List<String>? evidence,
    String? remediation,
    Map<String, Object?>? metadata,
  }) {
    return SecurityResult(
      id: id,
      timestamp: timestamp,
      source: source ?? this.source,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      target: target ?? this.target,
      confidence: confidence ?? this.confidence,
      evidence: evidence ?? this.evidence,
      remediation: remediation ?? this.remediation,
      metadata: metadata ?? this.metadata,
    );
  }
}
