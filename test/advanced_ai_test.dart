
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/ai/multi_agent_orchestrator.dart';
import 'package:project_zion/core/ai/long_term_memory.dart';

void main() {
  test('multi-agent routes defensive network request without executing it', () async {
    final memory = LongTermAIMemory();
    final results = await MultiAgentOrchestrator(memory: memory).analyze('حلل حالة شبكة WiFi محلية');
    expect(results.any((r) => r.role == AgentRole.orchestrator), isTrue);
    expect(results.any((r) => r.role == AgentRole.network), isTrue);
    expect(results.every((r) => r.risk != AgentRisk.blocked), isTrue);
  });
}
