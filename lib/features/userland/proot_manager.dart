import 'dart:io';
class ProotManager { Future<ProcessResult> shell(String root,String command) async=>Process.run('/system/bin/sh',['-c',command],workingDirectory:root); }