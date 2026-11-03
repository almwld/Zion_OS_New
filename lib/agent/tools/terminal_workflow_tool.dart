import '../core/agent_models.dart';
import '../core/cancellation_token.dart';
import '../../engine/terminal/terminal_workflow.dart';
import 'tool.dart';

class TerminalWorkflowTool extends AgentTool {
  TerminalWorkflowTool(this.workflow);
  final TerminalWorkflow? workflow;
  @override String get name=>'terminal_workflow';
  @override String get description=>'ينفذ مهمة طرفية بقائمة أوامر محددة وسياسات قراءة/كتابة، مع سجل واستئناف ودورة تشخيص محدودة.';
  @override Map<String,dynamic> get parameters=>const {
    'taskId':{'type':'string','required':true},
    'goal':{'type':'string','required':true},
    'commands':{'type':'array','items':{'type':'string'},'required':true},
    'context':{'type':'object','required':false}
  };
  @override Set<AgentPermission> get permissions=>const {AgentPermission.process};
  @override bool requiresApproval(Map<String,dynamic> params)=>false;
  @override Future<StepResult> execute(Map<String,dynamic> params)=>_run(params,null);
  @override Future<StepResult> executeCancellable(Map<String,dynamic> params,CancellationToken? cancellationToken)=>_run(params,cancellationToken);
  Future<StepResult> _run(Map<String,dynamic> params,CancellationToken? cancellationToken) async {
    final target=workflow;
    if(target==null)return StepResult.failure('سير عمل الطرفية غير متاح؛ افتح جلسة PTY أولاً.');
    final taskId=params['taskId']?.toString()??'';
    final goal=params['goal']?.toString()??'';
    final raw=params['commands'];
    if(raw is! List||raw.isEmpty||raw.length>40)return StepResult.failure('commands يجب أن تكون قائمة من 1 إلى 40 أمراً.');
    if(raw.any((e)=>e is! String))return StepResult.failure('كل عناصر commands يجب أن تكون نصوصاً.');
    final result=await target.run(taskId:taskId,goal:goal,commands:raw.cast<String>(),context:Map<String,dynamic>.from(params['context'] as Map? ?? const {}),cancel:cancellationToken);
    final data={'success':result.success,'repairCyclesUsed':result.repairCyclesUsed,'finalOutput':result.finalOutput,'attempts':result.attempts.map((e)=>e.toJson()).toList()};
    return result.success?StepResult.success('اكتمل سير العمل الطرفي.',data:data):StepResult.failure(result.error??'فشل سير العمل الطرفي.');
  }
}
