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

  void _register(AgentTool tool) {
    final name = tool.name.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(tool.name, 'tool.name', 'Tool name cannot be empty.');
    }
    if (name != tool.name) {
      throw ArgumentError.value(tool.name, 'tool.name', 'Tool names cannot contain surrounding whitespace.');
    }
    if (_tools.containsKey(name)) {
      throw ArgumentError.value(name, 'tool.name', 'A tool with this name is already registered.');
    }
    _tools[name] = tool;
  }

  /// Registers a new tool without silently replacing a built-in or existing
  /// implementation. This keeps the model-visible tool contract unambiguous.
  void register(AgentTool tool) => _register(tool);

  AgentTool? getTool(String name) => _tools[name];

  List<String> get availableTools => _tools.keys.toList(growable: false);
}
