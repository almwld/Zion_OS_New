import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/system/system_agent.dart';

void main() {
  test('system agent registry exposes defensive local agents', () {
    expect(SystemAgentRegistry.definitions.length, 4);
    expect(SystemAgentRegistry.byId('system'), isNotNull);
    expect(SystemAgentRegistry.byId('network')!.action, 'network');
    expect(SystemAgentRegistry.byId('security')!.description, contains('دفاعية'));
  });

  test('unknown agent returns empty plan', () {
    final plan = SystemAgentCoordinator().planFor('missing');
    expect(plan.steps, isEmpty);
  });
}
