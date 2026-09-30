import 'package:shared_preferences/shared_preferences.dart';
enum AIUserLevel { beginner, intermediate, expert }
class AdaptiveAIProfile {
 static const _levelKey='zion_ai_user_level_v1',_commandsKey='zion_ai_command_count_v1',_errorsKey='zion_ai_error_count_v1';
 AIUserLevel level=AIUserLevel.beginner;int commands=0,errors=0;
 Future<void> load() async{final p=await SharedPreferences.getInstance();commands=p.getInt(_commandsKey)??0;errors=p.getInt(_errorsKey)??0;level=AIUserLevel.values.firstWhere((e)=>e.name==(p.getString(_levelKey)??'beginner'),orElse:()=>AIUserLevel.beginner);}
 Future<void> recordCommand({bool error=false}) async{commands++;if(error)errors++;final p=await SharedPreferences.getInstance();await p.setInt(_commandsKey,commands);await p.setInt(_errorsKey,errors);final rate=commands==0?0:errors/commands;level=rate>0.30?AIUserLevel.beginner:(rate<0.05&&commands>=20?AIUserLevel.expert:AIUserLevel.intermediate);await p.setString(_levelKey,level.name);}
}
