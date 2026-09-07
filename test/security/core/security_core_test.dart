import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/security/core/audit_logger.dart';
import 'package:project_zion/security/core/authorization_policy.dart';
import 'package:project_zion/security/core/event_bus.dart';
import 'package:project_zion/security/core/risk_engine.dart';
import 'package:project_zion/security/core/security_event.dart';
import 'package:project_zion/security/core/security_result.dart';

void main() {
  SecurityResult result({
    SecuritySeverity severity = SecuritySeverity.high,
    ResultSource source = ResultSource.real,
    double confidence = 1,
  }) {
    return SecurityResult(
      id: 'test-1',
      timestamp: DateTime.utc(2026, 1, 1),
      source: source,
      severity: severity,
      title: 'test finding',
      description: 'test',
      confidence: confidence,
    );
  }

  test('simulation is explicitly distinguishable from operational data', () {
    expect(result(source: ResultSource.simulated).isSimulation, isTrue);
    expect(result(source: ResultSource.simulated).isOperational, isFalse);
    expect(result(source: ResultSource.real).isOperational, isTrue);
  });

  test('risk engine reduces simulated evidence influence', () {
    const engine = RiskEngine();
    final real = engine.assess(<SecurityResult>[result()]);
    final simulated = engine.assess(<SecurityResult>[
      result(source: ResultSource.simulated),
    ]);

    expect(real.score, greaterThan(simulated.score));
    expect(real.severity, SecuritySeverity.high);
  });

  test('event bus publishes normalized security events', () async {
    final bus = SecurityEventBus();
    final future = bus.stream.first;
    bus.publish(SecurityEvent(
      id: 'event-1',
      timestamp: DateTime.utc(2026, 1, 1),
      type: 'finding.created',
      result: result(),
    ));

    final event = await future;
    expect(event.type, 'finding.created');
    await bus.dispose();
  });

  test('audit logger stores immutable records', () {
    final logger = AuditLogger(clock: () => DateTime.utc(2026, 1, 1));
    logger.log(action: 'scan.start', actor: 'test', outcome: 'accepted');

    expect(logger.records, hasLength(1));
    expect(logger.records.single.timestamp, DateTime.utc(2026, 1, 1));
    expect(() => logger.records.add(logger.records.single), throwsUnsupportedError);
  });

  test('authorization blocks expired and simulation-only actions', () {
    const policy = AuthorizationPolicy();
    final expired = AuthorizationScope(
      target: 'lab.local',
      mode: SecurityMode.labSimulation,
      expiresAt: DateTime.utc(2020, 1, 1),
    );
    expect(
      policy.canExecute(
        scope: expired,
        action: 'simulation.run',
        requiresSimulation: true,
      ),
      isFalse,
    );

    final defensive = AuthorizationScope(
      target: 'device',
      mode: SecurityMode.defensive,
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    expect(
      policy.canExecute(
        scope: defensive,
        action: 'simulation.run',
        requiresSimulation: true,
      ),
      isFalse,
    );
  });
}
