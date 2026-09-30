import 'agent_models.dart';
class AgentExecutionPolicy {
 final int maxSteps; final Duration stepTimeout; final bool allowNetwork,allowProcess,allowLocalWrite;
 const AgentExecutionPolicy({this.maxSteps=20,this.stepTimeout=const Duration(seconds:60),this.allowNetwork=false,this.allowProcess=false,this.allowLocalWrite=true});
 Set<AgentPermission> get granted{final s=<AgentPermission>{AgentPermission.readOnly};if(allowNetwork)s.add(AgentPermission.network);if(allowProcess)s.add(AgentPermission.process);if(allowLocalWrite)s.add(AgentPermission.localWrite);return s;}
}