import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class AIMemoryEntry {
 final String id,kind,text; final DateTime timestamp; final Map<String,dynamic> metadata;
 const AIMemoryEntry({required this.id,required this.kind,required this.text,required this.timestamp,this.metadata=const {}});
 Map<String,dynamic> toJson()=>{'id':id,'kind':kind,'text':text,'timestamp':timestamp.toIso8601String(),'metadata':metadata};
 factory AIMemoryEntry.fromJson(Map<String,dynamic> j)=>AIMemoryEntry(id:j['id']?.toString()??'',kind:j['kind']?.toString()??'event',text:j['text']?.toString()??'',timestamp:DateTime.tryParse(j['timestamp']?.toString()??'')??DateTime.now(),metadata:Map<String,dynamic>.from(j['metadata'] is Map ? j['metadata'] : const {}));
}
class LongTermAIMemory {
 static const _key='zion_ai_long_term_memory_v1'; final List<AIMemoryEntry> _entries=[]; bool _loaded=false;
 List<AIMemoryEntry> get entries=>List.unmodifiable(_entries);
 Future<void> load() async { if(_loaded)return; final p=await SharedPreferences.getInstance(); final raw=p.getStringList(_key)??const <String>[]; _entries..clear()..addAll(raw.map((s)=>AIMemoryEntry.fromJson(Map<String,dynamic>.from(jsonDecode(s) as Map)))); _loaded=true; }
 Future<void> remember({required String kind,required String text,Map<String,dynamic> metadata=const {}}) async {await load();_entries.add(AIMemoryEntry(id:'m_\${DateTime.now().microsecondsSinceEpoch}',kind:kind,text:text,timestamp:DateTime.now(),metadata:metadata));if(_entries.length>500)_entries.removeRange(0,_entries.length-500);await _save();}
 List<AIMemoryEntry> search(String query,{int limit=20}) {final q=query.trim().toLowerCase();if(q.isEmpty)return entries.reversed.take(limit).toList();final terms=q.split(RegExp(r'\s+')).where((e)=>e.isNotEmpty).toList();final scored=_entries.map((e){final hay='\${e.kind} \${e.text} \${jsonEncode(e.metadata)}'.toLowerCase();final score=terms.where(hay.contains).length;return (e,score);}).where((x)=>x.\$2>0).toList()..sort((a,b)=>b.\$2.compareTo(a.\$2));return scored.take(limit).map((x)=>x.\$1).toList();}
 Future<void> clear() async{_entries.clear();await _save();} Future<void> _save() async{final p=await SharedPreferences.getInstance();await p.setStringList(_key,_entries.map((e)=>jsonEncode(e.toJson())).toList());}
}
