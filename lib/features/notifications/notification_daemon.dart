import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ZionNotificationType { info, success, warning, error, system, security, update }

@immutable
class ZionDesktopNotification {
  const ZionDesktopNotification({required this.id, required this.title, required this.message, required this.type, required this.timestamp, this.read = false, this.source = 'system', this.actionKey});
  final String id; final String title; final String message; final ZionNotificationType type; final DateTime timestamp; final bool read; final String source; final String? actionKey;
  ZionDesktopNotification copyWith({bool? read}) => ZionDesktopNotification(id:id,title:title,message:message,type:type,timestamp:timestamp,read:read ?? this.read,source:source,actionKey:actionKey);
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'message':message,'type':type.name,'timestamp':timestamp.toIso8601String(),'read':read,'source':source,if(actionKey!=null)'actionKey':actionKey};
  factory ZionDesktopNotification.fromJson(Map<String,dynamic> j){
    final type=ZionNotificationType.values.firstWhere((v)=>v.name==j['type'],orElse:()=>ZionNotificationType.info);
    return ZionDesktopNotification(id:(j['id'] ?? DateTime.now().microsecondsSinceEpoch).toString(),title:'${j['title'] ?? ''}',message:'${j['message'] ?? ''}',type:type,timestamp:DateTime.tryParse('${j['timestamp'] ?? ''}') ?? DateTime.now(),read:j['read']==true,source:'${j['source'] ?? 'system'}',actionKey:j['actionKey']?.toString());
  }
}

class NotificationDaemon extends ChangeNotifier {
  NotificationDaemon({this.maxHistory=200,this.storageKey='zion.notification_daemon.v1'});
  final int maxHistory; final String storageKey; final List<ZionDesktopNotification> _items=[]; bool _initialized=false; Future<void> _writeQueue=Future<void>.value();
  bool get isInitialized=>_initialized; List<ZionDesktopNotification> get notifications=>List.unmodifiable(_items); int get unreadCount=>_items.where((n)=>!n.read).length;
  Future<void> init() async { if(_initialized)return; final p=await SharedPreferences.getInstance(); final raw=p.getString(storageKey); if(raw!=null&&raw.isNotEmpty){try{final d=jsonDecode(raw);if(d is List){_items..clear()..addAll(d.whereType<Map>().map((e)=>ZionDesktopNotification.fromJson(Map<String,dynamic>.from(e))));}}catch(_){_items.clear();}} _initialized=true; notifyListeners(); }
  Future<void> add({required String title,required String message,ZionNotificationType type=ZionNotificationType.info,String source='system',String? id,String? actionKey}) async { await init(); final item=ZionDesktopNotification(id:id ?? DateTime.now().microsecondsSinceEpoch.toString(),title:title,message:message,type:type,timestamp:DateTime.now(),source:source,actionKey:actionKey); if(_items.any((n)=>n.id==item.id))return; _items.insert(0,item); if(_items.length>maxHistory)_items.removeRange(maxHistory,_items.length); notifyListeners(); await _persist(); }
  Future<void> markRead(String id) async {await init();final i=_items.indexWhere((n)=>n.id==id);if(i<0||_items[i].read)return;_items[i]=_items[i].copyWith(read:true);notifyListeners();await _persist();}
  Future<void> markAllRead() async {await init();var changed=false;for(var i=0;i<_items.length;i++){if(!_items[i].read){_items[i]=_items[i].copyWith(read:true);changed=true;}}if(changed){notifyListeners();await _persist();}}
  Future<void> remove(String id) async {await init();final before=_items.length;_items.removeWhere((n)=>n.id==id);if(before!=_items.length){notifyListeners();await _persist();}}
  Future<void> clear() async {await init();if(_items.isEmpty)return;_items.clear();notifyListeners();await _persist();}
  Future<void> _persist(){_writeQueue=_writeQueue.then((_){return SharedPreferences.getInstance().then((p)=>p.setString(storageKey,jsonEncode(_items.map((n)=>n.toJson()).toList())));});return _writeQueue;}
}