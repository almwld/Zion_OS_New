import 'package:shared_preferences/shared_preferences.dart';
class CommandHistory {
  static const key='zion.terminal.history';
  final int maxEntries;
  CommandHistory({this.maxEntries=500});
  Future<void> add(String command) async {
    final value=command.trim(); if(value.isEmpty)return;
    final p=await SharedPreferences.getInstance(); final history=p.getStringList(key)??<String>[];
    history.remove(value); history.insert(0,value);
    await p.setStringList(key,history.take(maxEntries).toList());
  }
  Future<List<String>> all() async=>(await SharedPreferences.getInstance()).getStringList(key)??<String>[];
  Future<List<String>> search(String query) async {
    final q=query.toLowerCase().trim(); final values=await all();
    if(q.isEmpty)return values; return values.where((x)=>x.toLowerCase().contains(q)).toList();
  }
  Future<String?> navigate(int index) async {final values=await all();return index>=0&&index<values.length?values[index]:null;}
  Future<void> clear() async=>(await SharedPreferences.getInstance()).remove(key);
}
