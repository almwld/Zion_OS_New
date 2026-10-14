import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/ai/llama_service.dart';
import 'package:project_zion/agent/tools/ai_tool.dart';
import 'package:project_zion/agent/tools/tool_registry.dart';

void main() {
  test('AI tool uses the same local model service as the orchestrator', () {
    final service = LlamaService();
    final registry = ToolRegistry(ai: service);
    final tool = registry.getTool('ai') as AITool;

    expect(identical(tool.service, service), isTrue);
  });
}
