import 'dart:convert';
import 'dart:async';
import 'package:sqlite3/sqlite3.dart';
import '../../security/core/audit_logger.dart';

class WorkflowEvent {
  const WorkflowEvent({required this.taskId,required this.type,required this.message,this.data=const {},required this.timestamp});
  final String taskId,type,message;
  final Map<String,dynamic> data;
  final DateTime timestamp;
}
class AgentEventBus {
  final StreamController<WorkflowEvent> _events=StreamController<WorkflowEvent>.broadcast();
  Stream<WorkflowEvent> get stream=>_events.stream;
  void emit(WorkflowEvent event){if(!_events.isClosed)_events.add(event);}
  Future<void> dispose()=>_events.close();
}
class AuditLog {
  AuditLog(this.db,{AuditLogger? logger}):_logger=logger;
  final Database db;
  final AuditLogger? _logger;
  void init(){
    db.execute('CREATE TABLE IF NOT EXISTS terminal_workflow_audit(id INTEGER PRIMARY KEY AUTOINCREMENT,timestamp TEXT NOT NULL,task_id TEXT NOT NULL,action TEXT NOT NULL,command TEXT NOT NULL,phase TEXT NOT NULL,approved INTEGER NOT NULL,exit_code INTEGER,error TEXT,output_size INTEGER NOT NULL)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_terminal_audit_task ON terminal_workflow_audit(task_id,id)');
  }
  Future<void> record({required String taskId,required String action,required String command,required String phase,required bool approved,int? exitCode,String? error,int outputSize=0}) async {
    final now=DateTime.now().toUtc();
    db.execute('INSERT INTO terminal_workflow_audit(timestamp,task_id,action,command,phase,approved,exit_code,error,output_size) VALUES(?,?,?,?,?,?,?,?,?)',
      [now.toIso8601String(),taskId,action,command,phase,approved?1:0,exitCode,error,outputSize]);
    _logger?.log(action:'terminal_workflow.$action',actor:'zion-agent',outcome:exitCode==null?'started':(exitCode==0?'success':'failed'),target:command,
      metadata:{'task_id':taskId,'phase':phase,'approved':approved,'exit_code':exitCode,'error':error,'output_size':outputSize});
  }
  Future<List<Map<String,Object?>>> recent({int limit=100}) async => db.select('SELECT * FROM terminal_workflow_audit ORDER BY id DESC LIMIT ?',[limit.clamp(1,1000)]).map((r)=>Map<String,Object?>.from(r)).toList();
}
