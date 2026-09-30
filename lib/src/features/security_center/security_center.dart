import 'package:flutter/material.dart';
import '../../../security/core/security_core.dart';
import '../../../security/runtime/runtime_integrity.dart';
class SecurityCenter extends StatefulWidget { const SecurityCenter({super.key}); @override State<SecurityCenter> createState()=>_SecurityCenterState(); }
class _SecurityCenterState extends State<SecurityCenter> {
 final SecurityCore _core=SecurityCore(); final RuntimeIntegrity _integrity=const RuntimeIntegrity(); RuntimeIntegrityReport? _report;
 @override void initState(){super.initState();_verify();}
 void _verify(){final report=_integrity.verify(_core);if(mounted)setState(()=>_report=report);}
 @override void dispose(){_core.dispose();super.dispose();}
 @override Widget build(BuildContext context){final report=_report;final passed=report?.passed??false;final records=_core.auditLogger.records.reversed.take(25).toList();final auditWidgets=<Widget>[];if(records.isEmpty){auditWidgets.add(const Padding(padding:EdgeInsets.all(20),child:Text('No audit records yet.',style:TextStyle(color:Colors.white54))));}else{auditWidgets.addAll(records.map<Widget>((r)=>ListTile(dense:true,leading:const Icon(Icons.receipt_long,color:Color(0xFF00BCD4)),title:Text(r.action,style:const TextStyle(color:Colors.white,fontSize:12)),subtitle:Text('${r.outcome} • ${r.target??'local'} • ${r.timestamp.toLocal()}',style:const TextStyle(color:Colors.white54,fontSize:10))));}return Scaffold(backgroundColor:const Color(0xFF070B10),appBar:AppBar(title:const Text('Security Center'),backgroundColor:const Color(0xFF101923),actions:[IconButton(onPressed:_verify,icon:const Icon(Icons.refresh))]),body:ListView(padding:const EdgeInsets.all(16),children:[
 Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFF101923),borderRadius:BorderRadius.circular(18),border:Border.all(color:passed?Colors.greenAccent:Colors.orangeAccent)),child:Row(children:[Icon(passed?Icons.verified_user:Icons.warning_amber,color:passed?Colors.greenAccent:Colors.orangeAccent,size:42),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(passed?'Runtime integrity passed':'Runtime integrity needs attention',style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)),const Text('Authorization, audit and risk engine are checked at runtime.',style:TextStyle(color:Colors.white60))]))])),
 const SizedBox(height:16),const Text('Integrity checks',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)),
 ...(report?.checks.entries.map((e)=>ListTile(leading:Icon(e.value?Icons.check_circle:Icons.error,color:e.value?Colors.greenAccent:Colors.orangeAccent),title:Text(e.key,style:const TextStyle(color:Colors.white)),trailing:Text(e.value?'PASS':'FAIL',style:TextStyle(color:e.value?Colors.greenAccent:Colors.orangeAccent,fontWeight:FontWeight.bold))))??const <Widget>[]),
 const SizedBox(height:12),const Text('Recent audit events',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)),
 ...auditWidgets,
 ]));}
}