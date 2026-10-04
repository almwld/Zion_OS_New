import 'package:shared_preferences/shared_preferences.dart';
class DistroRegistry {
  static const key='zion.userland.distros';
  Future<List<String>> list() async=>(await SharedPreferences.getInstance()).getStringList(key)??<String>[];
  Future<void> add(String name) async {final p=await SharedPreferences.getInstance();final v=p.getStringList(key)??<String>[];if(!v.contains(name)){v.add(name);await p.setStringList(key,v);}}
  Future<void> remove(String name) async {final p=await SharedPreferences.getInstance();final v=p.getStringList(key)??<String>[];v.remove(name);await p.setStringList(key,v);}
  Future<bool> contains(String name) async=>(await list()).contains(name);
}
