import 'dart:async';
import 'package:flutter/material.dart';
import '../core/agent_models.dart';
import '../core/agent_runtime.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});
  @override State<AgentScreen> createState()=>_AgentScreenState();
}
class _AgentScreenState extends State<AgentScreen> {
  late final AgentRuntime _runtime;
  final _input=TextEditingController();
  final _scroll=ScrollController();
  final _events=<AgentEvent>[];
  StreamSubscription<AgentEvent>? _sub;
  AgentResult? _result;
  bool _approve=false;

  @override void initState(){super.initState();_runtime=AgentRuntime();_sub=_runtime.events.listen((e){if(!mounted)return;setState(()=>_events.add(e));WidgetsBinding.instance.addPostFrameCallback((_){if(_scroll.hasClients)_scroll.jumpTo(_scroll.position.maxScrollExtent);});});}
  Future<void> _run() async {
    final task=_input.text.trim(); if(task.isEmpty||_runtime.canCancel)return;
    _input.clear();setState(()=>_result=null);
    final r=await _runtime.run(task,approveReviewed:_approve);if(mounted)setState(()=>_result=r);
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFF070B08),
    appBar:AppBar(title:const Text('Zion Agent'),backgroundColor:const Color(0xFF0B120E),actions:[
      Row(children:[
        const Text('السماح بالخطوات المراجعة',style:TextStyle(fontSize:11)),
        Switch(value:_approve,onChanged:_runtime.canCancel?null:(v)=>setState(()=>_approve=v)),
        if(_runtime.canApprove) ...[
          IconButton(onPressed:(){_runtime.approve();setState((){});},icon:const Icon(Icons.check_circle_outline,color:Colors.greenAccent),tooltip:'الموافقة على الخطوة'),
          IconButton(onPressed:(){_runtime.deny();setState((){});},icon:const Icon(Icons.cancel_outlined,color:Colors.orangeAccent),tooltip:'رفض الخطوة'),
        ],
        if(_runtime.canCancel)IconButton(onPressed:_cancel,icon:const Icon(Icons.stop_circle_outlined,color:Colors.redAccent),tooltip:'إلغاء المهمة')
      ])
    ]),
    body:Column(children:[
      Container(width:double.infinity,padding:const EdgeInsets.all(10),color:const Color(0xFF0B120E),child:Wrap(spacing:12,runSpacing:6,children:[
        Chip(label:Text(_stateText(_runtime.orchestrator.state))),Chip(label:Text('الأدوات: '+_runtime.orchestrator.tools.availableTools.join(', '))),if(_runtime.canCancel)const Chip(label:Text('قابل للإلغاء')),
      ])),
      Expanded(child:ListView.builder(controller:_scroll,itemCount:_events.length,itemBuilder:(c,i)=>Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),child:Text(
        '['+_events[i].timestamp.toLocal().toString().substring(11,19)+'] '+_events[i].message,
        style:TextStyle(color:_color(_events[i]),fontFamily:'monospace',fontSize:12),
      )))),
      if(_result!=null)Container(constraints:const BoxConstraints(maxHeight:180),padding:const EdgeInsets.all(12),margin:const EdgeInsets.all(8),decoration:BoxDecoration(color:const Color(0xFF0B120E),borderRadius:BorderRadius.circular(10)),child:SingleChildScrollView(child:Text(
        _result!.success?(_result!.report??'اكتملت المهمة.'):('المهمة متوقفة: '+(_result!.error??'خطأ غير معروف')),
        style:const TextStyle(color:Colors.white70),
      ))),
      Padding(padding:const EdgeInsets.all(10),child:Row(children:[
        Expanded(child:TextField(enabled:!_runtime.canCancel,controller:_input,onSubmitted:(_)=>_run(),style:const TextStyle(color:Colors.white),decoration:const InputDecoration(hintText:'اكتب مهمة معقدة للوكيل...',border:OutlineInputBorder()))),
        const SizedBox(width:8),IconButton(onPressed:_runtime.canCancel?null:_run,icon:const Icon(Icons.play_arrow,color:Color(0xFF00FF41)),tooltip:'تنفيذ')
      ]))
    ])
  );
  String _stateText(AgentState s){switch(s){case AgentState.idle:return'جاهز';case AgentState.planning:return'تخطيط';case AgentState.executing:return'تنفيذ';case AgentState.evaluating:return'تقييم';case AgentState.waitingApproval:return'بانتظار الموافقة';case AgentState.completed:return'اكتمل';case AgentState.failed:return'فشل';case AgentState.cancelled:return'أُلغي';}}
  Color _color(AgentEvent e){if(e.message.contains('❌')||e.message.contains('⛔'))return Colors.redAccent;if(e.message.contains('🔐'))return Colors.orangeAccent;if(e.message.contains('✅'))return Colors.greenAccent;return Colors.white70;}
  Future<void> _cancel() async { await _runtime.cancel(); if(mounted)setState((){});}
  @override void dispose(){_sub?.cancel();_runtime.dispose();_input.dispose();_scroll.dispose();super.dispose();}
}
