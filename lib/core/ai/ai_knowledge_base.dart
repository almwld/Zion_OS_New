import 'long_term_memory.dart';
class AIKnowledgeBase {
 final LongTermAIMemory memory;
 AIKnowledgeBase(this.memory);
 Future<void> recordFailure(String operation,String error,String safeResolution) async{
  await memory.remember(kind:'learning',text:operation,metadata:{'error':error,'resolution':safeResolution});
 }
 List<AIMemoryEntry> findLessons(String query)=>memory.search(query,limit:10).where((e)=>e.kind=='learning').toList();
}
