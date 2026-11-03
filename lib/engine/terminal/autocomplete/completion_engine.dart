import 'command_dictionary.dart';
import 'command_history.dart';\nimport 'context_provider.dart';

enum CompletionType { command,subcommand,parameter,path,value }
class Completion {
  const Completion({required this.text,required this.display,required this.description,required this.type,required this.replaceStart,required this.replaceEnd});
  final String text,display,description;
  final CompletionType type;
  final int replaceStart,replaceEnd;
}
class CompletionEngine {
  CompletionEngine({required this.dictionary,required this.history,this.context});
  final CommandDictionary dictionary;
  final CommandHistory history;\n  final ContextProvider? context;
  Future<List<Completion>> complete(String input,int cursorPosition) async {
    final cursor=cursorPosition.clamp(0,input.length).toInt();
    final before=input.substring(0,cursor);
    final tokenStart=before.lastIndexOf(' ')+1;
    final current=before.substring(tokenStart);
    final previous=before.substring(0,tokenStart).trim();
    final results=<Completion>[];
    if(previous.isEmpty){
      final recent=await history.matching(current,limit:10);
      for(final e in recent){results.add(Completion(text:e.command,display:e.command,description:'من سجل الأوامر • ${e.frequency} مرات',type:CompletionType.command,replaceStart:0,replaceEnd:cursor));}
      for(final name in dictionary.allCommands.where((e)=>e.startsWith(current))){
        if(results.any((e)=>e.text==name))continue;
        results.add(Completion(text:name,display:name,description:dictionary.describe(name)??'',type:CompletionType.command,replaceStart:tokenStart,replaceEnd:cursor));
      }
    }else{
      final tokens=previous.split(RegExp(r'\s+'));
      final base=tokens.first;
      final context=<String,dynamic>{};
      final candidates=await dictionary.suggestParameters(base,current,context);
      for(final candidate in candidates){
        results.add(Completion(text:candidate,display:candidate,description:'اقتراح أمر فرعي',type:tokens.length==1?CompletionType.subcommand:CompletionType.parameter,replaceStart:tokenStart,replaceEnd:cursor));
      }
      if(results.isEmpty){
        final similar=await history.similar(current,limit:5);
        for(final entry in similar){results.add(Completion(text:entry.command,display:entry.command,description:'أمر سابق مشابه',type:CompletionType.value,replaceStart:0,replaceEnd:cursor));}
      }
    }
    return results.take(12).toList();
  }
}
