import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'memory_layer.dart';
class MemoryEntry {
 final int? id;final MemoryLayer layer;final String content;final Map<String,dynamic> metadata;final DateTime createdAt;final double importance;
 const MemoryEntry({this.id,required this.layer,required this.content,this.metadata=const {},required this.createdAt,this.importance=0.5});
}
class MemoryStore {
 final Database db;MemoryStore(this.db);
 void init(){
  db.execute("CREATE TABLE IF NOT EXISTS engine_memory(id INTEGER PRIMARY KEY AUTOINCREMENT,layer TEXT NOT NULL,content TEXT NOT NULL,metadata_json TEXT NOT NULL DEFAULT '{}',importance REAL NOT NULL DEFAULT 0.5,created_at INTEGER NOT NULL)");
  db.execute('CREATE INDEX IF NOT EXISTS idx_engine_memory_layer ON engine_memory(layer,created_at DESC)');
 }
 int add(MemoryEntry e){
  db.execute('INSERT INTO engine_memory(layer,content,metadata_json,importance,created_at) VALUES(?,?,?,?,?)',
  [e.layer.name,e.content,jsonEncode(e.metadata),e.importance.clamp(0,1),e.createdAt.millisecondsSinceEpoch]);
  return db.lastInsertRowId;
 }
 List<MemoryEntry> recent({MemoryLayer? layer,int limit=100}){
  final rows=layer==null?db.select('SELECT * FROM engine_memory ORDER BY importance DESC,created_at DESC LIMIT ?',[limit.clamp(1,1000)]):
   db.select('SELECT * FROM engine_memory WHERE layer=? ORDER BY importance DESC,created_at DESC LIMIT ?',[layer.name,limit.clamp(1,1000)]);
  return rows.map((r)=>MemoryEntry(id:r['id'] as int,layer:MemoryLayer.values.byName(r['layer'] as String),content:r['content'] as String,
   metadata:jsonDecode(r['metadata_json'] as String) as Map<String,dynamic>,importance:(r['importance'] as num).toDouble(),
   createdAt:DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int))).toList();
 }
 void delete(int id)=>db.execute('DELETE FROM engine_memory WHERE id=?',[id]);
 void clearLayer(MemoryLayer layer)=>db.execute('DELETE FROM engine_memory WHERE layer=?',[layer.name]);
}