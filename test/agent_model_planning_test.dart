import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/core/orchestrator.dart';
import 'package:project_zion/agent/core/agent_models.dart';
import 'package:project_zion/agent/tools/tool.dart';
import 'package:project_zion/agent/tools/tool_registry.dart';
import 'package:project_zion/ai/llama_service.dart';

const _aiChannel = MethodChannel('zion.os/ai');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('invalid local-model plan fails without running a heuristic fallback', () async {
    var toolExecutions = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_aiChannel, (call) async {
      switch (call.method) {
        case 'isLoaded':
          return true;
        case 'generate':
          return 'هذا ليس JSON صالحاً';
        case 'freeModel':
          return null;
        default:
          return null;
      }
    });

    // Simulate the model being loaded by the Offline AI screen through a
    // different LlamaService instance: the native model is ready, while this
    // service's local isLoaded flag starts false.
    final ai = LlamaService();
    final orchestrator = AgentOrchestrator(
      ai: ai,
      tools: ToolRegistry(customTools: [_CountingTool(() => toolExecutions++)]),
    );

    final result = await orchestrator.executeTask(
      'ماهي مخرجاتك',
      stepTimeout: const Duration(seconds: 2),
    );

    expect(result.success, isFalse);
    expect(result.error, contains('لم ينتج النموذج خطة JSON صالحة'));
    expect(toolExecutions, 0);

    orchestrator.dispose();
    await ai.unloadModel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_aiChannel, null);
  });
}

class _CountingTool extends AgentTool {
  final void Function() onExecute;
  _CountingTool(this.onExecute);

  @override
  String get name => 'ai';

  @override
  String get description => 'Test-only counting tool';

  @override
  Map<String, dynamic> get parameters => const {'prompt': 'string'};

  @override
  Future<StepResult> execute(Map<String, dynamic> params) async {
    onExecute();
    return StepResult.success('executed');
  }
}
