import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

enum WorkflowPhase { recon, executing, repairing, completed, failed, paused }

class ExecutedCommand {
  const ExecutedCommand({required this.command, this.stdout = '', this.stderr = '', required this.exitCode, required this.timestamp, this.approved = false});
  final String command, stdout, stderr;
  final int exitCode;
  final DateTime timestamp;
  final bool approved;
  Map<String, dynamic> toJson() => {'command':command,'stdout':stdout,'stderr':stderr,'exitCode':exitCode,'timestamp':timestamp.toIso8601String(),'approved':approved};
  factory ExecutedCommand.fromJson(Map<String,dynamic> j) => ExecutedCommand(command:j['command'] as String,stdout:j['stdout'] as String? ?? '',stderr:j['stderr'] as String? ?? '',exitCode:j['exitCode'] as int? ?? -1,timestamp:DateTime.parse(j['timestamp'] as String),approved:j['approved'] as bool? ?? false);
}

class WorkflowState {
  const WorkflowState({required this.taskId, required this.goal, required this.phase, this.commands = const [], this.attempts = const [], required this.lastUpdate, this.context = const {}, this.nextCommandIndex = 0});
  final String taskId, goal;
  final WorkflowPhase phase;
  final List<ExecutedCommand> commands;
  final List<Map<String,dynamic>> attempts;
  final DateTime lastUpdate;
  final Map<String,dynamic> context;
  final int nextCommandIndex;
  WorkflowState copyWith({WorkflowPhase? phase,List<ExecutedCommand>? commands,List<Map<String,dynamic>>? attempts,DateTime? lastUpdate,int? nextCommandIndex}) =>
    WorkflowState(taskId:taskId,goal:goal,phase:phase ?? this.phase,commands:commands ?? this.commands,attempts:attempts ?? this.attempts,lastUpdate:lastUpdate ?? DateTime.now(),context:context,nextCommandIndex:nextCommandIndex ?? this.nextCommandIndex);
  Map<String,dynamic> toJson() => {'taskId':taskId,'goal':goal,'phase':phase.name,'commands':commands.map((e)=>e.toJson()).toList(),'attempts':attempts,'lastUpdate':lastUpdate.toIso8601String(),'context':context,'nextCommandIndex':nextCommandIndex};
  factory WorkflowState.fromJson(Map<String,dynamic> j) => WorkflowState(taskId:j['taskId'] as String,goal:j['goal'] as String,phase:WorkflowPhase.values.firstWhere((e)=>e.name==j['phase'],orElse:()=>WorkflowPhase.failed),commands:(j['commands'] as List? ?? const []).map((e)=>ExecutedCommand.fromJson(Map<String,dynamic>.from(e as Map))).toList(),attempts:(j['attempts'] as List? ?? const []).map((e)=>Map<String,dynamic>.from(e as Map)).toList(),lastUpdate:DateTime.parse(j['lastUpdate'] as String),context:Map<String,dynamic>.from(j['context'] as Map? ?? const {}),nextCommandIndex:j['nextCommandIndex'] as int? ?? 0);
}

class WorkflowStateStore {
  WorkflowStateStore(this.db);
  final Database db;
  void init() {
    db.execute('CREATE TABLE IF NOT EXISTS workflow_states (task_id TEXT PRIMARY KEY, state_json TEXT NOT NULL, phase TEXT NOT NULL, updated_at INTEGER NOT NULL)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_workflow_phase ON workflow_states(phase, updated_at)');
  }
  Future<void> save(WorkflowState state) async => db.execute('INSERT INTO workflow_states(task_id,state_json,phase,updated_at) VALUES(?,?,?,?) ON CONFLICT(task_id) DO UPDATE SET state_json=excluded.state_json,phase=excluded.phase,updated_at=excluded.updated_at',
    [state.taskId,jsonEncode(state.toJson()),state.phase.name,state.lastUpdate.millisecondsSinceEpoch]);
  Future<WorkflowState?> load(String taskId) async {
    final rows = db.select('SELECT state_json FROM workflow_states WHERE task_id=?',[taskId]);
    if (rows.isEmpty) return null;
    return WorkflowState.fromJson(Map<String,dynamic>.from(jsonDecode(rows.first['state_json'] as String) as Map));
  }
  Future<List<WorkflowState>> loadPending() async => db.select("SELECT state_json FROM workflow_states WHERE phase IN ('recon','executing','repairing','paused') ORDER BY updated_at")
    .map((r)=>WorkflowState.fromJson(Map<String,dynamic>.from(jsonDecode(r['state_json'] as String) as Map))).toList();
}
