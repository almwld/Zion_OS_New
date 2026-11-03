import 'dart:async';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import '../agent/core/agent_models.dart';
import '../agent/core/cancellation_token.dart';
import '../agent/tools/tool.dart';
import '../features/terminal/terminal_service.dart';
import 'environment/agent_environment.dart';
import 'tools/execution/file_tool.dart';
import 'tools/execution/python_tool.dart';
import 'tools/execution/process_control_tool.dart';
import 'tools/execution/terminal_tool.dart';
import 'approval/approval_gate.dart';
import 'config/engine_config.dart';
import 'config/engine_mode.dart';
import 'memory/memory_layer.dart';
import 'memory/memory_retriever.dart';
import 'memory/memory_store.dart';
import 'providers/provider_selector.dart';
import 'recovery/recovery_engine.dart';
import 'recovery/repair_loop.dart';
import 'state/task_state_store.dart';
import 'tools/github/build_monitor.dart';
import 'tools/github/build_monitor_tool.dart';
import 'tools/github/github_client.dart';
import 'tools/github/github_read_tool.dart';
import 'tools/github/github_write_tool.dart';
import 'verification/build_verifier.dart';
import 'verification/verification_engine.dart';

class EngineEvent {
 final String taskId,type,message;final DateTime timestamp;final Map<String,dynamic> data;
 const EngineEvent({required this.taskId,required this.type,required this.message,required this.timestamp,this.data=const {}});
}
class EngineTaskResult {
 final String taskId,report;final bool success;final List<Map<String,dynamic>> steps;
 const EngineTaskResult({required this.taskId,required this.success,required this.report,this.steps=const []});
}
class ZionEngine {
 final EngineConfig config;final ProviderSelector providers;final Database database;
 final GitHubClient? github;final ApprovalGate approvals;final TaskStateStore states;final MemoryStore memory;
 final AgentEnvironment environment;final bool terminalLease;
 final Map<String,AgentTool> _tools={};final _events=StreamController<EngineEvent>.broadcast();
 bool _initialized=false,_disposed=false;
 BuildMonitor? _buildMonitor;RepairLoop? _repairLoop;
 Stream<EngineEvent> get events=>_events.stream;
 Stream<ApprovalRequest> get approvalRequests=>approvals.requests;
 EngineMode get mode=>providers.currentMode;
 ZionEngine({required this.config,required this.providers,required this.database,required this.approvals,
 required this.states,required this.memory,required this.environment,this.terminalLease=false,this.github});

 Future<void> init()async{
  if(_disposed)throw StateError('المحرك مغلق');if(_initialized)return;
  await states.init();await memory.init();
  await environment.prepareSandbox();
  _register(TerminalTool(environment));_register(PythonTool(environment));
  _register(FileTool(environment));_register(ProcessControlTool(environment));
  if(github!=null){
   _buildMonitor=BuildMonitor(github!,interval:config.buildPollInterval,timeout:config.buildTimeout);
   _register(GitHubReadTool(github!));_register(GitHubWriteTool(github!));_register(BuildMonitorTool(_buildMonitor!));
   _repairLoop=RepairLoop(config:config,github:github!,approvals:approvals,monitor:_buildMonitor!,
    provider:()=>providers.current,recovery:RecoveryEngine(()=>providers.current));
  }
  _initialized=true;
 }
 void registerTool(AgentTool tool){if(_disposed)throw StateError('المحرك مغلق');_register(tool);}
 void _register(AgentTool tool)=>_tools[tool.name]=tool;
 void _emit(String id,String type,String message,[Map<String,dynamic> data=const {}]){
  if(!_events.isClosed)_events.add(EngineEvent(taskId:id,type:type,message:message,timestamp:DateTime.now(),data:data));
 }
 Future<void> switchMode(EngineMode mode)=>providers.switchTo(mode);
 bool respondToApproval(String requestId,{required bool approved,String? reason})=>approvals.respond(requestId,approved:approved,reason:reason);

 Future<EngineTaskResult> runTask({required String goal,Map<String,dynamic> context=const {},CancellationToken? cancellationToken})async{
  if(!_initialized)await init();if(_disposed)throw StateError('المحرك مغلق');
  if(providers.currentMode==EngineMode.unset)throw StateError('اختر وضع الذكاء الاصطناعي قبل تشغيل المهمة');
  final id='zion-${DateTime.now().microsecondsSinceEpoch}',created=DateTime.now();
  final results=<Map<String,dynamic>>[];
  states.save(StoredTaskState(taskId:id,goal:goal,status:'running',context:context,createdAt:created,updatedAt:DateTime.now()));
  memory.add(MemoryEntry(layer:MemoryLayer.task,content:goal,metadata:context,createdAt:DateTime.now(),importance:0.8));
  _emit(id,'analysis','تحليل المهمة: $goal');
  final system='''أنت وكيل Zion OS البرمجي. استخدم الأدوات المتاحة فقط.
أعد في كل دور JSON صالحاً فقط بأحد الشكلين:
{"type":"tool","name":"tool_name","params":{},"reason":"سبب التنفيذ"}
{"type":"final","success":true,"report":"تقرير دقيق"}
لا تخترع نتائج الأدوات أو SHA أو أسماء ملفات. اقرأ الحالة والملفات أولاً. لا تنفذ كتابة قبل موافقة المستخدم.
الأدوات المتاحة:
${_tools.values.map((t)=>'${t.name}: ${t.description}; parameters=${t.parameters}').join('\n')}''';
  try{
   for(var index=0;index<config.maxStepsPerTask;index++){
    cancellationToken?.throwIfCancelled();
    if(DateTime.now().difference(created)>config.maxTaskDuration)throw TimeoutException('انتهت مهلة المهمة');
    final memoryContext=MemoryRetriever(memory).buildContext(goal,limit:10);
    final history=results.map(jsonEncode).join('\n');
    final prompt='الهدف: $goal\nالسياق: $context\nالذاكرة ذات الصلة:\n$memoryContext\nنتائج التنفيذ:\n$history\nأخرج JSON للخطوة التالية أو التقرير النهائي.';
    final raw=await providers.current.generate(prompt:prompt,systemPrompt:system,maxTokens:config.maxTokensPerStep,temperature:0.1);
    final decision=_parse(raw);
    if(decision['type']=='final'){
     var success=decision['success']==true;var report=decision['report']?.toString()??'انتهت المهمة دون تقرير';
     if(success&&github!=null&&(context['pr']!=null||context['sha']!=null||context['ref']!=null)){
      final verifier=BuildVerifier(github:github!,owner:context['owner']?.toString()??config.githubOwner??'',
       repo:context['repo']?.toString()??config.githubRepo??'',pullNumber:(context['pr'] as num?)?.toInt(),
       ref:context['sha']?.toString()??context['ref']?.toString());
      final verification=await VerificationEngine([verifier]).verifyAll(context);
      for(final v in verification){_emit(id,'verification',v.details,{'passed':v.passed,'verifier':v.verifier});if(!v.passed){success=false;report='$report\nالتحقق النهائي لم ينجح: ${v.details}';}}
     }
     final status=success?'completed':'failed';
     states.save(StoredTaskState(taskId:id,goal:goal,status:status,context:context,steps:results,createdAt:created,updatedAt:DateTime.now()));
     memory.add(MemoryEntry(layer:MemoryLayer.conversation,content:'$goal\n$report',metadata:{'success':success},createdAt:DateTime.now(),importance:0.6));
     _emit(id,'completion',report,{'success':success});
     return EngineTaskResult(taskId:id,success:success,report:report,steps:results);
    }
    if(decision['type']!='tool')throw FormatException('قرار النموذج غير صالح: $raw');
    final name=decision['name']?.toString()??'';final params=Map<String,dynamic>.from(decision['params'] as Map? ?? const {});
    final tool=_tools[name];if(tool==null)throw StateError('الأداة غير مسجلة: $name');
    final permissions=tool.requiredPermissions(params);
    final needsApproval=tool.requiresApproval(params)||permissions.contains(AgentPermission.externalSideEffect)||
      (config.requireApprovalForNetwork&&permissions.contains(AgentPermission.network));
    if(needsApproval){
     final request=ApprovalRequest(id:'$id-$index',taskId:id,action:'$name: ${decision['reason']??''}',
      risk:permissions.contains(AgentPermission.externalSideEffect)?'مرتفع':'متوسط',details:{'params':params},createdAt:DateTime.now());
     _emit(id,'approval_request','بانتظار موافقة المستخدم',{'requestId':request.id,'tool':name,'params':params});
     final answer=await approvals.request(request);
     if(!answer.approved){results.add({'tool':name,'success':false,'error':'رفض المستخدم: ${answer.reason??''}'});continue;}
    }
    _emit(id,'tool_call','تنفيذ $name',{'params':params});
    final started=DateTime.now();
    final result=await tool.executeCancellable(params,cancellationToken);
    final record=<String,dynamic>{'tool':name,'success':result.success,'summary':result.summary,
      'data':_bounded(result.data),'error':result.error,'durationMs':DateTime.now().difference(started).inMilliseconds};
    results.add(record);_emit(id,'observation',result.summary,record);
    states.save(StoredTaskState(taskId:id,goal:goal,status:'running',context:context,steps:results,createdAt:created,updatedAt:DateTime.now()));
    if(!result.success&&name=='wait_build'&&_repairLoop!=null){
     final owner=params['owner']?.toString()??context['owner']?.toString()??config.githubOwner;
     final repo=params['repo']?.toString()??context['repo']?.toString()??config.githubRepo;
     final branch=params['ref']?.toString()??context['branch']?.toString();
     if(owner!=null&&repo!=null&&branch!=null){
      final repair=await _repairLoop!.run(taskId:id,owner:owner,repo:repo,branch:branch,goal:goal,
       failure:result.error??result.summary,logs:result.error??result.summary);
      _emit(id,'recovery',repair.report,{'success':repair.success,'cycles':repair.cycles});
      results.add({'tool':'repair_loop','success':repair.success,'summary':repair.report});
     }
    }
   }
   const report='تجاوز الوكيل الحد الأقصى للخطوات دون تقرير نهائي.';
   states.save(StoredTaskState(taskId:id,goal:goal,status:'failed',context:context,steps:results,createdAt:created,updatedAt:DateTime.now(),error:report));
   _emit(id,'error',report);return EngineTaskResult(taskId:id,success:false,report:report,steps:results);
  }catch(e){
   final report='فشلت المهمة: $e';
   states.save(StoredTaskState(taskId:id,goal:goal,status:'failed',context:context,steps:results,createdAt:created,updatedAt:DateTime.now(),error:report));
   _emit(id,'error',report);return EngineTaskResult(taskId:id,success:false,report:report,steps:results);
  }
 }
 Map<String,dynamic> _parse(String raw){
  final a=raw.indexOf('{'),b=raw.lastIndexOf('}');
  if(a<0||b<=a)throw FormatException('لم يُرجع النموذج JSON صالحاً');
  return Map<String,dynamic>.from(jsonDecode(raw.substring(a,b+1)) as Map);
 }
 dynamic _bounded(dynamic value){
  try{final encoded=jsonEncode(value);return encoded.length<=12000?value:{'truncated':true,'preview':encoded.substring(0,12000)};}
  catch(_){return value?.toString();}
 }
 Future<void> dispose()async{
  if(_disposed)return;_disposed=true;
  await approvals.dispose();await providers.dispose();await github?.dispose();
  if(terminalLease)await environment.terminal?.releaseForAgent();
  await _events.close();database.dispose();
 }
}