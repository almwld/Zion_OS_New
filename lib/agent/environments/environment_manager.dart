import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AgentEnvironment {
  final String name;
  final Directory root;
  AgentEnvironment(this.name,this.root);

  Directory get filesDir=>Directory(root.path+'/files');
  Directory get outputDir=>Directory(root.path+'/output');
  Directory get cacheDir=>Directory(root.path+'/cache');

  Future<void> initialize() async {
    await filesDir.create(recursive:true);
    await outputDir.create(recursive:true);
    await cacheDir.create(recursive:true);
  }

  Future<ProcessResult> runProcess(String executable,List<String> args,{Duration timeout=const Duration(seconds:60)}) async {
    final p=await Process.start(executable,args,workingDirectory:root.path,environment:{
      'HOME':root.path,'TMPDIR':cacheDir.path,'PYTHONUSERBASE':root.path,
    });
    final out=StringBuffer(),err=StringBuffer();
    p.stdout.transform(SystemEncoding().decoder).listen(out.write);
    p.stderr.transform(SystemEncoding().decoder).listen(err.write);
    final code=await p.exitCode.timeout(timeout,onTimeout:(){p.kill(ProcessSignal.sigterm);return -1;});
    return ProcessResult(p.pid,code,out.toString(),err.toString());
  }

  Future<void> destroy() async { if(await root.exists()) await root.delete(recursive:true); }
}

class EnvironmentManager {
  static final Map<String,AgentEnvironment> _cache={};

  static Future<AgentEnvironment> getOrCreate(String name) async {
    final safe=_safeName(name);
    final cached=_cache[safe]; if(cached!=null){await cached.initialize();return cached;}
    final base=await getApplicationSupportDirectory();
    final root=Directory(base.path+'/zion-agent/environments/'+safe);
    final env=AgentEnvironment(safe,root); await env.initialize(); _cache[safe]=env; return env;
  }

  static Future<void> delete(String name) async { final env=_cache.remove(_safeName(name)); if(env!=null) await env.destroy(); }
  static Future<void> deleteAll() async { for(final env in _cache.values){await env.destroy();} _cache.clear(); }
  static String _safeName(String value)=>value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'),'_').substring(0,value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'),'_').length.clamp(0,48));
}
