import 'security_result.dart';

/// Central factory for findings entering the Security Core.
///
/// Adapters must use the appropriate source explicitly. In particular, lab
/// output is never silently promoted to operational telemetry.
class SecurityObservation {
  const SecurityObservation._();

  static SecurityResult real({
    required String id,
    required DateTime timestamp,
    required SecuritySeverity severity,
    required String title,
    required String description,
    String? target,
    double confidence = 0,
    List<String> evidence = const <String>[],
    String? remediation,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    return SecurityResult(
      id: id,
      timestamp: timestamp,
      source: ResultSource.real,
      severity: severity,
      title: title,
      description: description,
      target: target,
      confidence: confidence,
      evidence: List.unmodifiable(evidence),
      remediation: remediation,
      metadata: Map.unmodifiable(metadata),
    );
  }

  static SecurityResult simulated({
    required String id,
    required DateTime timestamp,
    required SecuritySeverity severity,
    required String title,
    required String description,
    String? target,
    double confidence = 0,
    List<String> evidence = const <String>[],
    String? remediation,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    return SecurityResult(
      id: id,
      timestamp: timestamp,
      source: ResultSource.simulated,
      severity: severity,
      title: title,
      description: description,
      target: target,
      confidence: confidence,
      evidence: List.unmodifiable(evidence),
      remediation: remediation,
      metadata: Map.unmodifiable(metadata),
    );
  }

  static SecurityResult unavailable({
    required String id,
    required DateTime timestamp,
    required String title,
    required String description,
    String? target,
    String? reason,
  }) {
    return SecurityResult(
      id: id,
      timestamp: timestamp,
      source: ResultSource.unavailable,
      severity: SecuritySeverity.info,
      title: title,
      description: description,
      target: target,
      confidence: 0,
      evidence: const <String>[],
      metadata: reason == null
          ? const <String, Object?>{}
          : <String, Object?>{'reason': reason},
    );
  }
}
