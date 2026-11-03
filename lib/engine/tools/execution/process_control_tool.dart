import '../../../agent/core/agent_models.dart';
import '../../../agent/tools/tool.dart';
import '../../environment/agent_environment.dart';

class ProcessControlTool extends AgentTool {
 final AgentEnvironment environment;ProcessControlTool(this.environment);
 @override String get name=>'process_control';
 @override String get description=>'مراقبة جلسة Zion PTY ومقاطعة الأمر الجاري؛ لا يتيح قتل عمليات النظام أو إدارة PID عشوائية.';
 @override Map<String,dynamic> get parameters=>const {'action':{'type':'string','required':true,'description':'status أو interrupt'}};
 @override Set<AgentPermission> requiredPermissions(Map<String,dynamic> p)=>p['action']=='status'?const {AgentPermission.readOnly}:const {AgentPermission.process};
 @override bool requiresApproval(Map<String,dynamic> p)=>p['action']=='interrupt';
 @override Future<StepResult> execute(Map<String,dynamic> p)async{
  final terminal=environment.terminal;if(terminal==null)return StepResult.failure('خدمة Terminal غير مرتبطة.');
  switch(p['action']){
   case 'status':return StepResult.success('حالة PTY الحالية.',data:{'running':terminal.isInteractiveRunning,'nativePty':terminal.isNativePtyRunning});
   case 'interrupt':if(!terminal.isInteractiveRunning)return StepResult.failure('لا توجد جلسة PTY نشطة.');await terminal.interruptInteractive();return StepResult.success('أُرسلت إشارة المقاطعة Ctrl-C إلى جلسة الوكيل.');
   default:return StepResult.failure('إجراء غير مدعوم.');
  }
 }
}