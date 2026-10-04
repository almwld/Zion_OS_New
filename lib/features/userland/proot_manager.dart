import 'dart:io';
class ProotManager {
  Future<ProcessResult> shell(String root,String command,{List<String> environment=[]}) async {
    if(command.trim().isEmpty)throw ArgumentError.value(command,'command');
    final env=<String,String>{...Platform.environment};
    for(final item in environment){final i=item.indexOf('=');if(i>0)env[item.substring(0,i)]=item.substring(i+1);}
    return Process.run('/system/bin/sh',['-c',command],workingDirectory:root,environment:env,includeParentEnvironment:true);
  }
  Future<Process> start(String root,String executable,List<String> args) async {
    return Process.start(executable,args,workingDirectory:root,mode:ProcessStartMode.normal);
  }
}
