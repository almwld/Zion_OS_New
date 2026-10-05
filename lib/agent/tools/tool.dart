import '../core/agent_models.dart';
abstract class AgentTool {
 String get name; String get description; Map<String,dynamic> get parameters;
 Set<AgentPermission> get permissions=>const {AgentPermission.readOnly};
 Set<AgentPermission> requiredPermissions(Map<String,dynamic> params)=>permissions;
 bool supports(Map<String,dynamic> params)=>true;
 Future<StepResult> execute(Map<String,dynamic> params);
}