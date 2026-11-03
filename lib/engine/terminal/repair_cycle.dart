import 'dart:async';
import '../../agent/core/cancellation_token.dart';
import '../../features/terminal/terminal_service.dart';
import '../approval/approval_gate.dart';
import 'command_policy.dart';
import 'error_classifier.dart';
import 'path_policy.dart';
import 'workflow_observability.dart';
import 'output_truncator.dart';

class RepairAttempt {
  const RepairAttempt({required this.cycle,required this.error,required this.strategy,this.diagnosticOutput=const [],this.repairOutput=const [],required this.verified,this.failureReason});
  final int cycle;
  final ClassifiedError error;
  final RepairStrategy strategy;
  final List<String> diagnosticOutput,repairOutput;
  final bool verified;
  final String? failureReason;
  Map<String,dynamic> toJson()=>{'cycle':cycle,'type':error.type.name,'message':error.rawMessage,'strategy':strategy.description,'diagnosticOutput':diagnosticOutput,'repairOutput':repairOutput,'verified':verified,'failureReason':failureReason};
}
class RepairResult {
  const RepairResult({required this.success,required this.cyclesUsed,this.finalOutput,this.error,this.attempts=const []});
  final bool success;
  final int cyclesUsed;
  final String? finalOutput,error;
  final List<RepairAttempt> attempts;
  factory RepairResult.failure(String error,{int cyclesUsed=0,List<RepairAttempt> attempts=const []})=>RepairResult(success:false,cyclesUsed:cyclesUsed,error:error,attempts:attempts);
}

class RepairCycle {
  RepairCycle({required this.terminal,required this.classifier,required this.commandPolicy,required this.pathPolicy,required this.approvalGate,required this.audit,required this.events,required this.taskIdProvider,this.cancel,OutputTruncator? truncator}) : truncator=truncator??const OutputTruncator();
  final TerminalService terminal;
  final ErrorClassifier classifier;
  final CommandPolicy commandPolicy;
  final PathPolicy pathPolicy;
  final ApprovalGate approvalGate;
  final AuditLog audit;
  final AgentEventBus events;
  final String Function() taskIdProvider;
  final CancellationToken? cancel;
  final OutputTruncator truncator;

  Future<RepairResult> run({required String taskId,required String failedCommand,required String stdout,required String stderr,required int exitCode,int maxCycles=3,CancellationToken? cancel}) async {
    var out=truncator.truncate(stdout),err=truncator.truncate(stderr),code=exitCode;
    final attempts=<RepairAttempt>[];
    final cap=maxCycles.clamp(1,3).toInt();
    for(var cycle=1;cycle<=cap;cycle++){
      (cancel ?? this.cancel)?.throwIfCancelled();
      final error=classifier.classify(out,err,code,command:failedCommand);
      events.emit(WorkflowEvent(taskId:taskId,type:'classification',message:'تصنيف الخطأ: ${error.type.name}',data:{'cycle':cycle,'error':error.rawMessage},timestamp:DateTime.now()));
      final strategy=classifier.suggestStrategy(error);
      if(error.type==ErrorType.unknown) {
        attempts.add(RepairAttempt(cycle:cycle,error:error,strategy:strategy,verified:false,failureReason:strategy.description));
        await approvalGate.request(ApprovalRequest(id:'$taskId-unknown-$cycle',taskId:taskId,action:'خطأ غير مفهوم يتطلب مراجعة: ${error.rawMessage}',risk:'متوسط',details:{'command':failedCommand},createdAt:DateTime.now()));
        return RepairResult.failure('خطأ غير مفهوم؛ أوقف الوكيل التنفيذ وطلب مراجعة المستخدم.',cyclesUsed:cycle,attempts:attempts);
      }
      if(error.type==ErrorType.outOfMemory) {
        attempts.add(RepairAttempt(cycle:cycle,error:error,strategy:strategy,verified:false,failureReason:strategy.description));
        return RepairResult.failure('نفدت الذاكرة؛ أوقفت الإصلاح الآلي.',cyclesUsed:cycle,attempts:attempts);
      }
      final diagnostics=<String>[];
      for(final command in strategy.diagnosticCommands){
        (cancel ?? this.cancel)?.throwIfCancelled();
        final policy=commandPolicy.check(command),path=pathPolicy.check(command);
        if(!policy.allowed||!path.allowed){diagnostics.add('مرفوض: ${policy.reason??path.reason}');continue;}
        try{
          final result=await terminal.executeInInteractive(command,timeout:const Duration(seconds:10));
          final text=[result.stdout,result.stderr].where((s)=>s.isNotEmpty).join('\n');
          diagnostics.add(text);
          await audit.record(taskId:taskId,action:'diagnostic',command:command,phase:'repairing',approved:false,exitCode:result.exitCode,outputSize:text.length);
        }catch(e){diagnostics.add('تعذر التشخيص: $e');await audit.record(taskId:taskId,action:'diagnostic_error',command:command,phase:'repairing',approved:false,error:e.toString());}
      }
      events.emit(WorkflowEvent(taskId:taskId,type:'diagnostic',message:'اكتمل التشخيص للدورة $cycle',data:{'output':diagnostics},timestamp:DateTime.now()));
      final repairs=<String>[];
      // لا تنفذ تثبيتاً أو رفع صلاحيات أو حذفاً ضمن دورة الإصلاح التلقائي.
      if(strategy.requiresElevation||strategy.modifiesSystem||strategy.repairCommands.isNotEmpty){
        final request=ApprovalRequest(id:'$taskId-repair-$cycle',taskId:taskId,action:'موافقة على إصلاح يتطلب تغييراً: ${strategy.description}',risk:'مرتفع',details:{'commands':strategy.repairCommands},createdAt:DateTime.now());
        final decision=await approvalGate.request(request);
        if(!decision.approved)return RepairResult.failure('لم تتم الموافقة على إجراء الإصلاح.',cyclesUsed:cycle,attempts:attempts);
        repairs.add('تمت الموافقة؛ لم يُنفذ أمر نظامي غير مدرج في سياسة التنفيذ.');
      }
      events.emit(WorkflowEvent(taskId:taskId,type:'repair',message:'تقييم الإصلاح: ${strategy.description}',data:{'output':repairs},timestamp:DateTime.now()));
      final verifyPolicy=commandPolicy.check(failedCommand),verifyPath=pathPolicy.check(failedCommand);
      if(!verifyPolicy.allowed||!verifyPath.allowed)return RepairResult.failure('تعذر إعادة التحقق لأن الأمر غير مسموح: ${verifyPolicy.reason??verifyPath.reason}',cyclesUsed:cycle,attempts:attempts);
      try{
        final verify=await terminal.executeInInteractive(failedCommand,timeout:const Duration(seconds:60));
        final verified=verify.exitCode==0;
        final attempt=RepairAttempt(cycle:cycle,error:error,strategy:strategy,diagnosticOutput:diagnostics,repairOutput:repairs,verified:verified,failureReason:verified?null:truncator.truncate(verify.stderr));
        attempts.add(attempt);
        await audit.record(taskId:taskId,action:'verify',command:failedCommand,phase:'repairing',approved:false,exitCode:verify.exitCode,error:verify.stderr,outputSize:verify.stdout.length);
        if(verified){
          events.emit(WorkflowEvent(taskId:taskId,type:'verified',message:'نجح التحقق بعد الدورة $cycle',data:{'output':verify.stdout},timestamp:DateTime.now()));
          return RepairResult(success:true,cyclesUsed:cycle,finalOutput:truncator.truncate(verify.stdout),attempts:attempts);
        }
        events.emit(WorkflowEvent(taskId:taskId,type:'verification_failed',message:'فشل التحقق في الدورة $cycle',data:{'stderr':verify.stderr},timestamp:DateTime.now()));
        out=truncator.truncate(verify.stdout);err=truncator.truncate(verify.stderr);code=verify.exitCode;
      }catch(e){return RepairResult.failure('تعذر تنفيذ التحقق: $e',cyclesUsed:cycle,attempts:attempts);}
    }
    events.emit(WorkflowEvent(taskId:taskId,type:'cycle_limit',message:'تم بلوغ حد الإصلاح $cap.',data:{'attempts':attempts.length},timestamp:DateTime.now()));
    await approvalGate.request(ApprovalRequest(id:'$taskId-cycle-limit',taskId:taskId,action:'وصل الإصلاح إلى حد $cap دورات فاشلة؛ هل تريد مراجعة الحالة؟',risk:'متوسط',details:{'command':failedCommand,'attempts':attempts.length},createdAt:DateTime.now()));
    return RepairResult.failure('فشلت $cap دورات إصلاح؛ توقف الوكيل بعد الحد المسموح.',cyclesUsed:cap,attempts:attempts);
  }
}
