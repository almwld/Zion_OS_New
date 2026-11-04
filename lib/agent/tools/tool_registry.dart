import '../../ai/llama_service.dart';
import '../core/agent_models.dart';
import 'ai_tool.dart';
import 'browser_tool.dart';
import 'calculator_tool.dart';
import 'current_datetime_tool.dart';
import 'data_tool.dart';
import 'file_tool.dart';
import 'http_tool.dart';
import 'python_tool.dart';
import 'shell_tool.dart';
import 'tool.dart';

class ToolRegistry {
  final Map<String, AgentTool> _tools = {};

  ToolRegistry({
    List<AgentTool> customTools = const [],
    LlamaService? ai,
  }) {
    _register(AITool(service: ai));
    _register(BrowserTool());
    _register(CalculatorTool());
    _register(CurrentDateTimeTool());
    _register(DataTool());
    _register(FileTool());
    _register(HttpTool());
    _register(PythonTool());
    _register(ShellTool());
    for (final tool in customTools) {
      _register(tool);
    }
  }

  void _register(AgentTool tool) => _tools[tool.name] = tool;

  void register(AgentTool tool) => _register(tool);

  AgentTool? getTool(String name) => _tools[name];

  List<String> get availableTools => _tools.keys.toList(growable: false);
}
