import '../core/agent_models.dart';
abstract class AgentTool { String get name; String get description; Map<String,dynamic> get parameters; Future<StepResult> execute(Map<String,dynamic> params); }
