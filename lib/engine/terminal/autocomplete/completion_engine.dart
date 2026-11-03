import 'command_dictionary.dart';
import 'command_history.dart';
import 'context_provider.dart';
import 'fuzzy_matcher.dart';

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
  final CommandHistory history;
  final ContextProvider? context;

  Future<List<Completion>> complete(String input,int cursorPosition) async {
    final cursor=cursorPosition.clamp(0,input.length).toInt();
    final before=input.substring(0,cursor);
    final tokenStart=before.lastIndexOf(' ')+1;
    final current=before.substring(tokenStart);
    final previous=before.substring(0,tokenStart).trim();
    final results=<Completion>[];
    if(previous.isEmpty) {
      final recent=await history.matching(current,limit:10);
      for(final entry in recent) {
        results.add(Completion(text:entry.command,display:entry.command,description:'من سجل الأوامر • ${entry.frequency} مرات',type:CompletionType.command,replaceStart:0,replaceEnd:cursor));
      }
      for(final name in dictionary.allCommands.where((e)=>e.startsWith(current))) {
        if(results.any((e)=>e.text==name))continue;
        final root=name.split(RegExp(r'\s+')).first;
        results.add(Completion(text:name,display:name,description:dictionary.describe(root)??'',type:CompletionType.command,replaceStart:tokenStart,replaceEnd:cursor));
      }
      if(results.isEmpty&&current.isNotEmpty) {
        final roots=dictionary.allCommands.map((c)=>c.split(RegExp(r'\s+')).first).where((c)=>c!='python3').toSet().toList();
        for(final name in FuzzyMatcher.suggest(current,roots,maxDistance:2)) {
          results.add(Completion(text:name,display:name,description:'هل تقصد $name؟',type:CompletionType.command,replaceStart:tokenStart,replaceEnd:cursor));
        }
      }
    } else {
      final tokens=previous.split(RegExp(r'\s+'));
      final base=tokens.first;
      final contextData=<String,dynamic>{};
      if(base=='git'&&tokens.length>=2&&tokens[1]=='checkout') {
        contextData['subcommand']='checkout';
        contextData['branches']=await context?.getBranches()??const <String>[];
      }
      final candidates=await dictionary.suggestParameters(base,current,contextData);
      for(final candidate in candidates) {
        results.add(Completion(text:candidate,display:candidate,description:contextData['subcommand']=='checkout'?'فرع Git محلي':'اقتراح أمر فرعي',type:tokens.length==1?CompletionType.subcommand:CompletionType.parameter,replaceStart:tokenStart,replaceEnd:cursor));
      }
      if(results.isEmpty) {
        final similar=await history.similar(current,limit:5);
        for(final entry in similar) {
          results.add(Completion(text:entry.command,display:entry.command,description:'أمر سابق مشابه',type:CompletionType.value,replaceStart:0,replaceEnd:cursor));
        }
      }
    }
    return results.take(12).toList();
  }
}
