import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/security/core/security_observation.dart';
import 'package:project_zion/security/core/security_result.dart';

void main() {
  test('real observations are explicitly operational', () {
    final result = SecurityObservation.real(
      id: 'real-1',
      timestamp: DateTime.utc(2026, 1, 1),
      severity: SecuritySeverity.high,
      title: 'Observed finding',
      description: 'Collected by a platform adapter.',
      confidence: 0.9,
      evidence: const <String>['adapter-output'],
    );

    expect(result.source, ResultSource.real);
    expect(result.isOperational, isTrue);
    expect(result.isTrustedTelemetry, isTrue);
  });

  test('simulation cannot become operational by construction', () {
    final result = SecurityObservation.simulated(
      id: 'sim-1',
      timestamp: DateTime.utc(2026, 1, 1),
      severity: SecuritySeverity.high,
      title: 'Lab finding',
      description: 'Generated inside a lab scenario.',
      confidence: 1,
    );

    expect(result.source, ResultSource.simulated);
    expect(result.isSimulation, isTrue);
    expect(result.isOperational, isFalse);
    expect(result.isTrustedTelemetry, isFalse);
  });

  test('observation collections are immutable', () {
    final result = SecurityObservation.real(
      id: 'immutable-1',
      timestamp: DateTime.utc(2026, 1, 1),
      severity: SecuritySeverity.low,
      title: 'Immutable',
      description: 'Immutable evidence.',
      evidence: const <String>['one'],
      metadata: const <String, Object?>{'source': 'test'},
    );

    expect(() => result.evidence.add('two'), throwsUnsupportedError);
    expect(() => result.metadata['x'] = 'y', throwsUnsupportedError);
  });

  test('unknown capabilities are unavailable, never simulated', () {
    final registry = SecurityCapabilityRegistry();
    final capability = registry.resolve('native.network.capture');

    expect(capability.isUnavailable, isTrue);
    expect(capability.isSimulation, isFalse);
  });
}
