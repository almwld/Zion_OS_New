import 'memory_layer.dart';
import 'memory_store.dart';
class MemoryRetriever {
 final MemoryStore store;MemoryRetriever(this.store);
 List<MemoryEntry> retrieve(String query,{List<MemoryLayer>? layers,int limit=12}){
  final terms=query.toLowerCase().split(RegExp(r'[^\p{L}\p{N}_]+',unicode:true)).where((e)=>e.length>1).toSet();
  if(terms.isEmpty)return const [];
  final found=<({MemoryEntry entry,int score})>[];
  for(final layer in layers??MemoryLayer.values){
   for(final e in store.recent(layer:layer,limit:300)){
    final text=' ${e.content.toLowerCase()} ${e.metadata.values.join(' ').toLowerCase()} ';
    final score=terms.where((t)=>text.contains(t)).length;
    if(score>0)found.add((entry:e,score:score));
   }
  }
  found.sort((a,b){final s=b.score.compareTo(a.score);return s!=0?s:b.entry.importance.compareTo(a.entry.importance);});
  return found.take(limit.clamp(1,100)).map((e)=>e.entry).toList();
 }
 String buildContext(String query,{int limit=12})=>retrieve(query,limit:limit).map((e)=>'[ ${e.layer.label} ] ${e.content}').join('\n');
}