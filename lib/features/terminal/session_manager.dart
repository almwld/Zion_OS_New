class TerminalSession {
  final String id;
  String title;
  final DateTime createdAt;
  bool connected;
  TerminalSession(this.id,{this.title='Terminal',DateTime? createdAt,this.connected=false})
      : createdAt=createdAt??DateTime.now();
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'createdAt':createdAt.toIso8601String(),'connected':connected};
  factory TerminalSession.fromJson(Map<String,dynamic> json)=>TerminalSession(
    json['id']?.toString()??DateTime.now().microsecondsSinceEpoch.toString(),
    title: json['title']?.toString()??'Terminal',
    createdAt: DateTime.tryParse(json['createdAt']?.toString()??'')??DateTime.now(),
    connected: json['connected']==true,
  );
}
class SessionManager {
  final List<TerminalSession> sessions=[];
  String? activeId;
  TerminalSession? get active {
    for(final session in sessions){if(session.id==activeId)return session;}
    return null;
  }
  TerminalSession create([String title='Terminal']){
    final s=TerminalSession('s-'+DateTime.now().microsecondsSinceEpoch.toString(),title:title);
    sessions.add(s); activeId=s.id; return s;
  }
  void switchTo(String id){if(sessions.any((s)=>s.id==id))activeId=id;}
  void close(String id){
    final index=sessions.indexWhere((s)=>s.id==id);
    if(index<0)return;
    sessions.removeAt(index);
    if(activeId==id)activeId=sessions.isEmpty?null:sessions[(index-1).clamp(0,sessions.length-1)].id;
  }
  void restore(Iterable<Map<String,dynamic>> data){
    sessions..clear()..addAll(data.map(TerminalSession.fromJson));
    activeId=sessions.isEmpty?null:sessions.last.id;
  }
  List<Map<String,dynamic>> serialize()=>sessions.map((s)=>s.toJson()).toList();
}
