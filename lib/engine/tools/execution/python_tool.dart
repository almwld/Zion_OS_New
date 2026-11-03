import 'dart:convert';
import 'dart:io';
import '../../../agent/core/agent_models.dart';
import '../../../agent/core/cancellation_token.dart';
import '../../../agent/tools/tool.dart';
import '../../environment/agent_environment.dart';

class PythonTool extends AgentTool {
 final AgentEnvironment environment;
 PythonTool(this.environment);
 @override String get name=>'run_python';
 @override String get description=>'تشغيل Python مع حارس تدقيق يمنع الشبكة وإنشاء العمليات والوصول للكتابة خارج sandbox.';
 @override Map<String,dynamic> get parameters=>const {
  'code':{'type':'string','required':true},
  'timeout_seconds':{'type':'integer','required':false},
 };
 @override Set<AgentPermission> get permissions=>const {AgentPermission.process,AgentPermission.localWrite};
 @override bool requiresApproval(Map<String,dynamic> p)=>true;
 String _quote(String value)=>"'"+value.replaceAll("'","'\\''")+"'";

 String _launcherSource()=>r'''
import os, sys, runpy
ROOT = os.path.realpath(sys.argv[1])
SCRIPT = os.path.realpath(sys.argv[2])
PREFIXES = tuple(os.path.realpath(p) for p in (ROOT, sys.prefix, sys.base_prefix, "/system") if p)
def inside(path, roots):
    try:
        value = os.path.realpath(os.fspath(path))
        return any(value == root or value.startswith(root + os.sep) for root in roots)
    except Exception:
        return False
def audit(event, args):
    if event.startswith("socket.") or event in {
        "subprocess.Popen", "os.system", "os.exec", "os.spawn", "os.fork",
        "os.posix_spawn", "os.startfile", "ctypes.dlopen", "ctypes.dlsym"
    }:
        raise PermissionError("Zion Python sandbox: network/process creation is disabled")
    if event == "open" and args:
        path = args[0]
        if isinstance(path, (str, bytes, os.PathLike)):
            mode = args[1] if len(args) > 1 else None
            flags = args[2] if len(args) > 2 and isinstance(args[2], int) else 0
            writing = (isinstance(mode, str) and any(c in mode for c in "wax+")) or bool(flags & (os.O_WRONLY | os.O_RDWR | os.O_CREAT | os.O_TRUNC | os.O_APPEND))
            roots = (ROOT,) if writing else PREFIXES
            if not inside(path, roots):
                raise PermissionError("Zion Python sandbox: file access outside the permitted roots")
    if event in {"os.listdir", "os.scandir"} and args and args[0] is not None:
        if not inside(args[0], PREFIXES):
            raise PermissionError("Zion Python sandbox: directory access denied")
    if event in {"os.remove", "os.unlink", "os.rmdir", "os.mkdir", "os.chmod", "os.chown"} and args:
        if not inside(args[0], (ROOT,)):
            raise PermissionError("Zion Python sandbox: filesystem mutation outside workspace denied")
    if event in {"os.rename", "os.replace", "os.link", "os.symlink"} and len(args) >= 2:
        if not inside(args[0], (ROOT,)) or not inside(args[1], (ROOT,)):
            raise PermissionError("Zion Python sandbox: filesystem mutation outside workspace denied")
os.chdir(ROOT)
sys.addaudithook(audit)
sys.argv = [SCRIPT]
runpy.run_path(SCRIPT, run_name="__main__")
''';

 @override Future<StepResult> executeCancellable(Map<String,dynamic> params,CancellationToken? token)async{
  if(token==null)return execute(params);
  token.throwIfCancelled();
  final service=environment.terminal;
  if(service==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final subscription=token.onCancel.listen((_)=>service.interruptInteractive());
  try{return await execute(params);}finally{await subscription.cancel();}
 }

 @override Future<StepResult> execute(Map<String,dynamic> params)async{
  final terminal=environment.terminal;
  if(terminal==null)return StepResult.failure('خدمة Terminal غير متاحة.');
  final code=params['code']?.toString();
  if(code==null||code.trim().isEmpty||code.length>100000)return StepResult.failure('كود Python فارغ أو يتجاوز 100KB.');
  final seconds=(params['timeout_seconds'] as num?)?.toInt()??30;
  if(seconds<1||seconds>300)return StepResult.failure('مهلة Python يجب أن تكون بين 1 و300 ثانية.');
  File? script,launcher;
  try{
   await environment.prepareSandbox();
   final id=DateTime.now().microsecondsSinceEpoch;
   script=File('${environment.tempDirectory.path}/agent_$id.py');
   launcher=File('${environment.tempDirectory.path}/launcher_$id.py');
   await script.writeAsString(code,flush:true);
   await launcher.writeAsString(_launcherSource(),flush:true);
   final root=await environment.sandboxRoot.resolveSymbolicLinks();
   final command='${environment.pythonCommand} -I ${_quote(launcher.path)} ${_quote(root)} ${_quote(script.path)}';
   final result=await terminal.executeInInteractive(command,timeout:Duration(seconds:seconds));
   final data={'stdout':result.stdout,'stderr':result.stderr,'exit_code':result.exitCode,
    'duration_ms':result.duration.inMilliseconds,'sandbox':root,'networkDisabledByAuditHook':true};
   return result.exitCode==0
    ?StepResult.success('Python اكتمل داخل قيود Zion sandbox.',data:data,duration:result.duration)
    :StepResult.failure('فشل Python (exit ${result.exitCode}): ${result.stderr.isEmpty?result.stdout:result.stderr}',duration:result.duration);
  }catch(e){return StepResult.failure('تعذر تشغيل Python: $e');}
  finally{for(final file in [script,launcher]){try{if(file!=null&&await file.exists())await file.delete();}catch(_){}}}
 }
}