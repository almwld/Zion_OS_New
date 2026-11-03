import 'command_dictionary.dart';
import 'command_history.dart';
import 'context_provider.dart';
import 'fuzzy_matcher.dart';
import '../command_policy.dart';

enum SuggestionType { frequent,recent,similar,fix,contextual }
class Suggestion {
  const Suggestion({required this.command,required this.reason,required this.type,required this.confidence});
  final String command,reason;
  final SuggestionType type;
  final double confidence;
}
class SuggestionEngine {
  SuggestionEngine({required this.history,required this.dictionary,required this.context});
  final CommandHistory history;
  final CommandDictionary dictionary;
  final ContextProvider context;
  final CommandPolicy policy=const CommandPolicy();

  Future<List<Suggestion>> suggest({int limit=5}) async {
    final recent=await history.matching('',limit:limit.clamp(1,20).toInt());
    final result=<Suggestion>[];
    for(final entry in recent) {
      if(policy.check(entry.command).allowed)result.add(Suggestion(command:entry.command,reason:'استخدمته ${entry.frequency} مرة',type:SuggestionType.frequent,confidence:0.9));
    }
    if(await context.isFlutterProject()&&!result.any((s)=>s.command=='flutter analyze'))result.add(const Suggestion(command:'flutter analyze',reason:'مشروع Flutter في المجلد الحالي',type:SuggestionType.contextual,confidence:0.8));
    if(await context.isGitRepo()&&!result.any((s)=>s.command=='git status'))result.add(const Suggestion(command:'git status',reason:'مستودع Git نشط',type:SuggestionType.contextual,confidence:0.85));
    return result.take(limit.clamp(1,20).toInt()).toList();
  }

  Future<List<Suggestion>> suggestFix(String failedCommand,String error) async {
    final roots=dictionary.allCommands.map((c)=>c.split(RegExp(r'\s+')).first).toSet().toList();
    final fixes=FuzzyMatcher.suggest(failedCommand.trim().split(RegExp(r'\s+')).first,roots,maxDistance:2);
    return fixes.take(5).map((name)=>Suggestion(command:name,reason:'هل تقصد $name؟ ($error)',type:SuggestionType.fix,confidence:0.7)).toList();
  }
}
