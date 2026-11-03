import '../../agent/core/cancellation_token.dart';
import '../../features/terminal/terminal_service.dart';
import '../approval/approval_gate.dart';
import 'command_policy.dart';
import 'error_classifier.dart';
import 'output_truncator.dart';
import 'path_policy.dart';
import 'repair_cycle.dart';
import 'workflow_observability.dart';
import 'workflow_state.dart';

class ReconResult {
  const ReconResult({this.systemInfo=const {},this.tools=const {},this.paths=const {},this.output=const []});
  final Map<String,String> systemInfo,tools,paths;
  final List<String> output;
}
class WorkflowResult {
  const WorkflowResult({required this.success,this.repairCyclesUsed=0,this.finalOutput='',this.error,this.attempts=const []});
  final bool success;
  final int repairCyclesUsed;
  final String finalOutput;
  final String? error;
  final List<RepairAttempt> attempts;
  factory WorkflowResult.failure(String error,{int cycles=0,List<RepairAttempt> attempts=const [],String output=''})=>WorkflowResult(success:false,repairCyclesUsed:cycles,error:error,attempts:attempts,finalOutput:output);
}

class TerminalWorkflow {
  TerminalWorkflow({required this.terminal,required this.stateStore,required this.approvalGate,required this.audit,required this.events,this.commandPolicy=const CommandPolicy(),PathPolicy? pathPolicy,ErrorClassifier? classifier,OutputTruncator? truncator})
    :pathPolicy=pathPolicy??PathPolicy(),classifier=classifier??ErrorClassifier(),truncator=truncator??const OutputTruncator(){
      repairCycle=RepairCycle(terminal:terminal,classifier:this.classifier,commandPolicy:commandPolicy,pathPolicy:this.pathPolicy,approvalGate:approvalGate,audit:audit,events:events,taskIdProvider:()=>_activeTaskId);
      stateStore.init();audit.init();
    }
  final TerminalService terminal;
  final WorkflowStateStore stateStore;
  final ApprovalGate approvalGate;
  final AuditLog audit;
  final AgentEventBus events;
  final CommandPolicy commandPolicy;
  final PathPolicy pathPolicy;
  final ErrorClassifier classifier;
  final OutputTruncator truncator;
  late final RepairCycle repairCycle;
  String _activeTaskId='';
  WorkflowState? _currentState;

  Future<void> _persistRecon(String command,String stdout,String stderr,int exitCode) async {
    final current=_currentState;
    if(current==null)return;
    final updated=current.copyWith(commands:[
      ...current.commands,
      ExecutedCommand(command:command,stdout:truncator.truncate(stdout),stderr:truncator.truncate(stderr),exitCode:exitCode,timestamp:DateTime.now())
    ]);
    _currentState=updated;
    await stateStore.save(updated);
  }

  Future<ReconResult> recon() async {
    const commands=<String>['whoami','id','pwd','ls -la','uname -a','df -h','git status','command -v flutter'];
    final outputs=<String>[];
    final tools=<String,String>{};
    for(final command in commands){
      final policy=commandPolicy.check(command);
      if(!policy.allowed||!await pathPolicy.checkAsync(command).allowed){outputs.add('$command: مرفوض');await audit.record(taskId:_activeTaskId,action:'recon_rejected',command:command,phase:'recon',approved:false,error:policy.reason??'مسار مرفوض');await _persistRecon(command,'',policy.reason??'مسار مرفوض',126);continue;}
      try{
        final result=await terminal.executeInInteractive(command,timeout:const Duration(seconds:10));
        final output=truncator.truncate(result.stdout.isEmpty?result.stderr:result.stdout);
        outputs.add('$command → $output');
        await audit.record(taskId:_activeTaskId,action:'recon',command:command,phase:'recon',approved:false,exitCode:result.exitCode,error:result.stderr.isEmpty?null:result.stderr,outputSize:output.length);
        events.emit(WorkflowEvent(taskId:_activeTaskId,type:'recon_step',message:'استطلاع: $command',data:{'exitCode':result.exitCode,'output':output},timestamp:DateTime.now()));
        await _persistRecon(command,result.stdout,result.stderr,result.exitCode);
        if(command.startsWith('command -v '))tools[command.substring(11)]=result.exitCode==0?output:'غير متاح';
      }catch(e){outputs.add('$command → تعذر التنفيذ: $e');await audit.record(taskId:_activeTaskId,action:'recon_error',command:command,phase:'recon',approved:false,error:e.toString());await _persistRecon(command,'',e.toString(),-1);}
    }
    events.emit(WorkflowEvent(taskId:_activeTaskId,type:'recon',message:'اكتمل الاستطلاع الأولي',data:{'commands':outputs},timestamp:DateTime.now()));
    return ReconResult(systemInfo:{'identity':outputs.isNotEmpty?outputs[0]:'','workingDirectory':outputs.length>2?outputs[2]:''},tools:tools,paths:{'workspace':outputs.length>2?outputs[2]:''},output:outputs);
  }

  Future<WorkflowResult> run({required String taskId,required String goal,required List<String> commands,Map<String,dynamic> context=const {},CancellationToken? cancel}) async {
    if(taskId.trim().isEmpty||goal.trim().isEmpty)return WorkflowResult.failure('taskId والهدف مطلوبان.');
    if(commands.isEmpty)return WorkflowResult.failure('لم يتم تحديد أوامر للتنفيذ.');
    final state=WorkflowState(taskId:taskId,goal:goal,phase:WorkflowPhase.recon,lastUpdate:DateTime.now(),context:{...context,'requestedCommands':commands});
    await stateStore.save(state);
    return _execute(state,commands,cancel:cancel,performRecon:true);
  }

  Future<WorkflowResult> resume(String taskId) async {
    final state=await stateStore.load(taskId);
    if(state==null)return WorkflowResult.failure('لا توجد مهمة محفوظة بالمعرّف $taskId.');
    if(state.phase==WorkflowPhase.completed)return WorkflowResult(success:true,finalOutput:state.commands.map((c)=>c.stdout).join('\n'));
    if(state.phase==WorkflowPhase.failed)return WorkflowResult.failure('المهمة محفوظة بحالة فشل.');
    final raw=state.context['requestedCommands'];
    if(raw is! List)return WorkflowResult.failure('الحالة لا تحتوي قائمة الأوامر الأصلية ولا يمكن استئنافها بأمان.');
    return _execute(state,raw.map((e)=>e.toString()).toList(),performRecon:state.phase==WorkflowPhase.recon);
  }

  Future<WorkflowResult> _execute(WorkflowState initial,List<String> commands,{CancellationToken? cancel,bool performRecon=false}) async {
    _activeTaskId=initial.taskId;
    var state=initial;
    _currentState=initial;
    final attempts=<RepairAttempt>[];
    final output=<String>[];
    try{
      if(performRecon){await recon();state=await stateStore.load(state.taskId)??state;state=state.copyWith(phase:WorkflowPhase.executing);_currentState=state;await stateStore.save(state);}
      for(var index=state.nextCommandIndex;index<commands.length;index++){
        if(cancel?.isCancelled==true){
          state=state.copyWith(phase:WorkflowPhase.paused,nextCommandIndex:index);await stateStore.save(state);
          return WorkflowResult.failure('تم إيقاف المهمة مؤقتاً ويمكن استئنافها.',cycles:attempts.fold(0,(n,a)=>n+a.cycle),attempts:attempts,output:output.join('\n'));
        }
        cancel?.throwIfCancelled();
        final command=commands[index];
        final policy=commandPolicy.check(command),path=await pathPolicy.checkAsync(command);
        if(!policy.allowed||!path.allowed){
          final reason=policy.reason??path.reason??'سياسة التنفيذ رفضت الأمر.';
          await audit.record(taskId:state.taskId,action:'rejected',command:command,phase:'executing',approved:false,error:reason);
          state=state.copyWith(phase:WorkflowPhase.failed);await stateStore.save(state);
          return WorkflowResult.failure('أمر مرفوض: $reason',cycles:attempts.fold(0,(n,a)=>n+a.cycle),attempts:attempts,output:output.join('\n'));
        }
        var approved=false;
        if(policy.requiresApproval){
          final decision=await approvalGate.request(ApprovalRequest(id:'${state.taskId}-command-$index',taskId:state.taskId,action:'تنفيذ أمر طرفية: $command',risk:'متوسط',details:{'command':command},createdAt:DateTime.now()));
          if(!decision.approved)return WorkflowResult.failure('رفض المستخدم تنفيذ الأمر: $command',attempts:attempts,output:output.join('\n'));
          approved=true;
        }
        await audit.record(taskId:state.taskId,action:'execute',command:command,phase:'executing',approved:approved);
        events.emit(WorkflowEvent(taskId:state.taskId,type:'execution',message:'تنفيذ: $command',timestamp:DateTime.now()));
        final result=await terminal.executeInInteractive(command,timeout:const Duration(seconds:30));
        final stdout=truncator.truncate(result.stdout),stderr=truncator.truncate(result.stderr);
        output.add(stdout.isEmpty?stderr:stdout);
        await audit.record(taskId:state.taskId,action:'terminal_run',command:command,phase:'executing',approved:approved,exitCode:result.exitCode,error:stderr.isEmpty?null:stderr,outputSize:stdout.length+stderr.length);
        final record=ExecutedCommand(command:command,stdout:stdout,stderr:stderr,exitCode:result.exitCode,timestamp:DateTime.now(),approved:approved);
        state=state.copyWith(commands:[...state.commands,record],nextCommandIndex:index+1);_currentState=state;await stateStore.save(state);
        if(result.exitCode!=0){
          state=state.copyWith(phase:WorkflowPhase.repairing);await stateStore.save(state);
          final repair=await repairCycle.run(taskId:state.taskId,failedCommand:command,stdout:result.stdout,stderr:result.stderr,exitCode:result.exitCode,cancel:cancel);
          attempts.addAll(repair.attempts);
          state=state.copyWith(attempts:[...state.attempts,...repair.attempts.map((a)=>a.toJson())],phase:repair.success?WorkflowPhase.executing:WorkflowPhase.failed);
          _currentState=state;
          await stateStore.save(state);
          if(!repair.success)return WorkflowResult.failure(repair.error??'فشل الإصلاح.',cycles:repair.cyclesUsed,attempts:attempts,output:output.join('\n'));
          if(repair.finalOutput!=null)output.add(truncator.truncate(repair.finalOutput!));
        }
      }
      state=state.copyWith(phase:WorkflowPhase.completed);_currentState=state;await stateStore.save(state);
      events.emit(WorkflowEvent(taskId:state.taskId,type:'completed',message:'اكتملت المهمة بنجاح.',data:{'commands':commands.length},timestamp:DateTime.now()));
      return WorkflowResult(success:true,repairCyclesUsed:attempts.fold(0,(n,a)=>n+a.cycle),finalOutput:output.join('\n'),attempts:attempts);
    }catch(e){
      state=state.copyWith(phase:e.toString().contains('cancel')?WorkflowPhase.paused:WorkflowPhase.failed);await stateStore.save(state);
      return WorkflowResult.failure('تعذر إكمال سير العمل: $e',cycles:attempts.fold(0,(n,a)=>n+a.cycle),attempts:attempts,output:output.join('\n'));
    }
  }
}
