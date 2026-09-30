import '../core/agent_models.dart';
import 'ai_tool.dart'; import 'browser_tool.dart'; import 'data_tool.dart'; import 'file_tool.dart'; import 'http_tool.dart'; import 'python_tool.dart'; import 'shell_tool.dart'; import 'tool.dart';
class ToolRegistry {
  final Map<String,AgentTool> _tools={};
  ToolRegistry({List<AgentTool> customTools=const []}){_register(AITool());_register(BrowserTool());_register(DataTool());_register(FileTool());_register(HttpTool());_register(PythonTool());_register(ShellTool());for(final t in customTools){_register(t);}}
  void _register(AgentTool t)=>_tools[t.name]=t; void register(AgentTool t)=>_register(t);
  AgentTool? getTool(String name)=>_tools[name]; List<String> get availableTools=>_tools.keys.toList(growable:false);
}
