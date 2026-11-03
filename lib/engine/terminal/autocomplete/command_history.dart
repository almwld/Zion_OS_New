import 'package:sqlite3/sqlite3.dart';
import 'fuzzy_matcher.dart';

class HistoryEntry {
  const HistoryEntry({required this.command,required this.frequency,required this.lastUsed,required this.exitCode});
  final String command;
  final int frequency;
  final DateTime lastUsed;
  final int exitCode;
}
class CommandHistory {
  CommandHistory(this.db);
  final Database db;
  void init(){
    db.execute('CREATE TABLE IF NOT EXISTS command_history(command TEXT PRIMARY KEY,frequency INTEGER DEFAULT 1,last_used INTEGER NOT NULL,exit_code INTEGER DEFAULT 0)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_command_history_last ON command_history(last_used DESC)');
  }
  Future<void> record(String command,{int exitCode=0}) async {
    final value=command.trim();
    if(value.isEmpty||value.length>2000)return;
    db.execute('INSERT INTO command_history(command,frequency,last_used,exit_code) VALUES(?,1,?,?) ON CONFLICT(command) DO UPDATE SET frequency=frequency+1,last_used=excluded.last_used,exit_code=excluded.exit_code',
      [value,DateTime.now().millisecondsSinceEpoch,exitCode]);
  }
  Future<List<HistoryEntry>> matching(String prefix,{int limit=10}) async {
    final rows=db.select("SELECT command,frequency,last_used,exit_code FROM command_history WHERE command LIKE ? ESCAPE '\\' ORDER BY frequency DESC,last_used DESC LIMIT ?",
      ['${_escape(prefix)}%',limit.clamp(1,100)]);
    return rows.map(_entry).toList();
  }
  Future<List<HistoryEntry>> similar(String partial,{int limit=5}) async {
    final rows=db.select('SELECT command,frequency,last_used,exit_code FROM command_history ORDER BY frequency DESC,last_used DESC LIMIT 500');
    final entries=rows.map(_entry).toList();
    final ranked=FuzzyMatcher.suggest(partial,entries.map((e)=>e.command).toList(),maxDistance:3);
    return ranked.take(limit.clamp(1,50)).map((c)=>entries.firstWhere((e)=>e.command==c)).toList();
  }
  HistoryEntry _entry(Row r)=>HistoryEntry(command:r['command'] as String,frequency:r['frequency'] as int,lastUsed:DateTime.fromMillisecondsSinceEpoch(r['last_used'] as int),exitCode:r['exit_code'] as int);
  String _escape(String value)=>value.replaceAll('\\','\\\\').replaceAll('%','\\%').replaceAll('_','\\_');
}
