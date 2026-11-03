import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
class StoredTaskState {
 final String taskId,goal,status;final Map<String,dynamic> context;final List<Map<String,dynamic>> steps;
 final DateTime createdAt,updatedAt;final String? error;
 const StoredTaskState({required this.taskId,required this.goal,required this.status,this.context=const {},this.steps=const [],required this.createdAt,required this.updatedAt,this.error});
 Map<String,dynamic> toJson()=>{'taskId':taskId,'goal':goal,'status':status,'context':context,'steps':steps,'createdAt':createdAt.toIso8601String(),'updatedAt':updatedAt.toIso8601String(),'error':error};
 factory StoredTaskState.fromJson(Map<String,dynamic> j)=>StoredTaskState(taskId:j['taskId'] as String,goal:j['goal'] as String,status:j['status'] as String,
 context:Map<String,dynamic>.from(j['context'] as Map? ?? const {}),steps:(j['steps'] as List? ??const []).map((e)=>Map<String,dynamic>.from(e as Map)).toList(),
 createdAt:DateTime.parse(j['createdAt'] as String),updatedAt:DateTime.parse(j['updatedAt'] as String),error:j['error'] as String?);
}
class TaskStateStore {
 final Database db;TaskStateStore(this.db);
 void init(){
  db.execute('CREATE TABLE IF NOT EXISTS engine_task_states(task_id TEXT PRIMARY KEY,status TEXT NOT NULL,state_json TEXT NOT NULL,created_at INTEGER NOT NULL,updated_at INTEGER NOT NULL)');
  db.execute('CREATE INDEX IF NOT EXISTS idx_engine_task_status ON engine_task_states(status,updated_at)');
 }
 void save(StoredTaskState s)=>db.execute('INSERT INTO engine_task_states(task_id,status,state_json,created_at,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(task_id) DO UPDATE SET status=excluded.status,state_json=excluded.state_json,updated_at=excluded.updated_at',
 [s.taskId,s.status,jsonEncode(s.toJson()),s.createdAt.millisecondsSinceEpoch,s.updatedAt.millisecondsSinceEpoch]);
 StoredTaskState? load(String id){final r=db.select('SELECT state_json FROM engine_task_states WHERE task_id=?',[id]);if(r.isEmpty)return null;return StoredTaskState.fromJson(jsonDecode(r.first['state_json'] as String) as Map<String,dynamic>);}
 List<StoredTaskState> loadPending()=>db.select("SELECT state_json FROM engine_task_states WHERE status IN ('running','paused','awaitingApproval') ORDER BY updated_at").map((r)=>StoredTaskState.fromJson(jsonDecode(r['state_json'] as String) as Map<String,dynamic>)).toList();
 void delete(String id)=>db.execute('DELETE FROM engine_task_states WHERE task_id=?',[id]);
}