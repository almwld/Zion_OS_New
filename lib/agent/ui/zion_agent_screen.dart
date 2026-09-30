import 'dart:async';
import 'package:flutter/material.dart';
import '../core/orchestrator.dart';
class ZionAgentScreen extends StatefulWidget{const ZionAgentScreen({super.key});@override State<ZionAgentScreen> createState()=>_ZionAgentScreenState();}
class _ZionAgentScreenState extends State<ZionAgentScreen>{
 final _input=TextEditingController();final _logs=<String>[];late final ZionAgent _agent;StreamSubscription<String>? _sub;bool _ready=false;bool _busy=false;AgentTaskResult? _result;
 @override void initState(){super.initState();_agent=ZionAgent();_sub=_agent.events.listen((e){if(mounted)setState(()=>_logs.add(e));});_init();}
 Future<void> _init()async{await _agent.initialize();if(mounted)setState(()=>_ready=true);}
 Future<void> _run()async{final task=_input.text.trim();if(task.isEmpty||!_ready||_busy)return;setState(()=>_busy=true);final r=await _agent.execute(task);if(mounted)setState((){_result=r;_busy=false;});}
 @override Widget build(BuildContext c)=>Scaffold(backgroundColor:const Color(0xFF071018),appBar:AppBar(title:const Text('Zion Agent'),backgroundColor:const Color(0xFF101923),actions:[Padding(padding:const EdgeInsets.all(12),child:Text(_ready?'LOCAL':'INIT',style:const TextStyle(color:Color(0xFF00BCD4))))]),body:Column(children:[
 Expanded(child:ListView(padding:const EdgeInsets.all(12),children:[..._logs.map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Text(e,style:const TextStyle(color:Colors.white70,fontFamily:'monospace')))),if(_result!=null)Card(color:const Color(0xFF101923),child:Padding(padding:const EdgeInsets.all(12),child:Text(_result!.report,style:const TextStyle(color:Colors.white))))])),
 Container(padding:const EdgeInsets.all(10),color:const Color(0xFF101923),child:Row(children:[Expanded(child:TextField(controller:_input,maxLines:3,style:const TextStyle(color:Colors.white),decoration:const InputDecoration(hintText:'اكتب مهمة معقدة...',hintStyle:TextStyle(color:Colors.white38),border:OutlineInputBorder()))),const SizedBox(width:8),IconButton(onPressed:_busy?null:_run,icon:const Icon(Icons.play_arrow,color:Color(0xFF00BCD4))) ]))
 ]));
 @override void dispose(){_sub?.cancel();_input.dispose();_agent.dispose();super.dispose();}
}