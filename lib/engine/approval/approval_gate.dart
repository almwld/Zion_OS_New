import 'dart:async';
class ApprovalRequest {
 final String id,taskId,action,risk;final Map<String,dynamic> details;final DateTime createdAt;
 const ApprovalRequest({required this.id,required this.taskId,required this.action,required this.risk,this.details=const {},required this.createdAt});
}
class ApprovalDecision {
 final bool approved;final String? reason;
 const ApprovalDecision.approve():approved=true,reason=null;
 const ApprovalDecision.reject([this.reason]):approved=false;
}
class ApprovalGate {
 final _controller=StreamController<ApprovalRequest>.broadcast();
 final Map<String,Completer<ApprovalDecision>> _pending={};
 Stream<ApprovalRequest> get requests=>_controller.stream;
 Future<ApprovalDecision> request(ApprovalRequest r,{Duration timeout=const Duration(minutes:10)})async{
  if(_pending.containsKey(r.id))throw StateError('طلب موافقة مكرر');
  final c=Completer<ApprovalDecision>();_pending[r.id]=c;_controller.add(r);
  try{return await c.future.timeout(timeout,onTimeout:()=>const ApprovalDecision.reject('انتهت مهلة الموافقة'));}
  finally{_pending.remove(r.id);}
 }
 bool respond(String id,{required bool approved,String? reason}){
  final c=_pending[id];if(c==null||c.isCompleted)return false;
  c.complete(approved?const ApprovalDecision.approve():ApprovalDecision.reject(reason));return true;
 }
 Future<void> dispose()async{
  for(final c in _pending.values){if(!c.isCompleted)c.complete(const ApprovalDecision.reject('تم إغلاق المحرك'));}
  _pending.clear();await _controller.close();
 }
}