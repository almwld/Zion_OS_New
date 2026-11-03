import 'dart:io';
import '../../features/terminal/terminal_service.dart';
class AgentEnvironmentStatus {
 final bool sandboxReady,terminalReady,pythonReady,gitReady;final String? pythonVersion,gitVersion,terminalError;
 const AgentEnvironmentStatus({required this.sandboxReady,required this.terminalReady,required this.pythonReady,required this.gitReady,this.pythonVersion,this.gitVersion,this.terminalError});
 bool get isReady=>sandboxReady&&terminalReady&&gitReady;
 Map<String,dynamic> toJson()=>{'sandboxReady':sandboxReady,'terminalReady':terminalReady,'pythonReady':pythonReady,'gitReady':gitReady,'pythonVersion':pythonVersion,'gitVersion':gitVersion,'terminalError':terminalError};
}
class AgentEnvironment {
 final TerminalService? terminal;final Directory sandboxRoot;final String pythonCommand;
 AgentEnvironment({required this.terminal,required this.sandboxRoot,this.pythonCommand='python3'});
 Directory get projectsDirectory=>Directory('${sandboxRoot.path}/projects');
 Directory get tempDirectory=>Directory('${sandboxRoot.path}/temp');
 Future<void> prepareSandbox()async{
  await sandboxRoot.create(recursive:true);await projectsDirectory.create(recursive:true);await tempDirectory.create(recursive:true);
  final root=await sandboxRoot.resolveSymbolicLinks();
  for(final d in [projectsDirectory,tempDirectory]){final p=await d.resolveSymbolicLinks();if(p!=root&&!p.startsWith('$root/'))throw FileSystemException('مسار مجلد sandbox خارج الجذر',p);}
 }
 Future<Directory?> resolveWorkspaceDirectory(String relative)async{
  if(relative.isEmpty||relative.startsWith('/')||relative.contains('..')||RegExp(r'[^A-Za-z0-9_./-]').hasMatch(relative))return null;
  final root=await projectsDirectory.resolveSymbolicLinks();
  final candidate=Directory('${projectsDirectory.path}/$relative');
  if(!await candidate.exists())return null;
  final resolved=await candidate.resolveSymbolicLinks();
  if(resolved!=root&&!resolved.startsWith('$root/'))return null;
  return Directory(resolved);
 }
 Future<AgentEnvironmentStatus> inspect()async{
  var t=false,p=false,g=false;String? pv,gv,error;final s=terminal;
  if(s==null){error='لم تُربط خدمة Zion Terminal بالوكيل.';}else{try{
   final ping=await s.executeInInteractive('printf ZION_PTY_READY',timeout:const Duration(seconds:8));t=ping.exitCode==0&&ping.stdout.contains('ZION_PTY_READY');if(!t)error=ping.stderr.isEmpty?ping.stdout:ping.stderr;
   if(t){final py=await s.executeInInteractive('$pythonCommand --version',timeout:const Duration(seconds:8));p=py.exitCode==0;pv=py.formatted;
    final git=await s.executeInInteractive('git --version',timeout:const Duration(seconds:8));g=git.exitCode==0;gv=git.formatted;}
  }catch(e){error=e.toString();}}
  return AgentEnvironmentStatus(sandboxReady:await sandboxRoot.exists(),terminalReady:t,pythonReady:p,gitReady:g,pythonVersion:pv,gitVersion:gv,terminalError:error);
 }
}