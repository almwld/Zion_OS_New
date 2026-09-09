import 'security_result.dart';

class RiskAssessment {
  const RiskAssessment({required this.score, required this.severity, required this.reasons});

  final double score;
  final SecuritySeverity severity;
  final List<String> reasons;
}

class RiskEngine {
  const RiskEngine();

  /// Assesses real security results by default.
  ///
  /// Simulated/demo findings are excluded rather than assigned an arbitrary
  /// weight. They can only be included when a caller explicitly opts in for a
  /// demonstration UI.
  RiskAssessment assess(
    Iterable<SecurityResult> results, {
    bool includeSimulated = false,
  }) {
    final findings = results
        .where((finding) => includeSimulated || finding.source != ResultSource.simulated)
        .toList(growable: false);

    if (findings.isEmpty) {
      return const RiskAssessment(
        score: 0,
        severity: SecuritySeverity.info,
        reasons: <String>[],
      );
    }

    double score = 0;
    final reasons = <String>[];
    for (final finding in findings) {
      final weight = switch (finding.severity) {
        SecuritySeverity.info => 0,
        SecuritySeverity.low => 10,
        SecuritySeverity.medium => 25,
        SecuritySeverity.high => 45,
        SecuritySeverity.critical => 70,
      };
      final confidenceMultiplier = finding.confidence.clamp(0.1, 1.0);
      score += weight * confidenceMultiplier;
      if (weight > 0) {
        reasons.add('${finding.title} (${finding.source.name})');
      }
    }

    score = score.clamp(0, 100).toDouble();
    return RiskAssessment(
      score: score,
      severity: _severityFor(score),
      reasons: reasons,
    );
  }

  SecuritySeverity _severityFor(double score) {
    if (score >= 80) return SecuritySeverity.critical;
    if (score >= 60) return SecuritySeverity.high;
    if (score >= 30) return SecuritySeverity.medium;
    if (score > 0) return SecuritySeverity.low;
    return SecuritySeverity.info;
  }
}
