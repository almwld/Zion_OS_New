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
  final _messages=<Map<String,String>>[];
  final _events=<AgentEvent>[];
  StreamSubscription<AgentEvent>? _sub;
  AgentResult? _result;
  bool _approve=false;

  @override void initState(){
    super.initState();
    _runtime=AgentRuntime();
    _messages.add(const {'role':'assistant','text':'مرحباً. أنا Zion Super Agent المحلي. صف لي ما تريد إنجازه بلغة طبيعية، وسأخطط للخطوات وأعرض التنفيذ والنتائج أمامك.'});
    _sub=_runtime.events.listen((e){
      if(!mounted)return;
      setState(()=>_events.add(e));
      _scrollEnd();
    });
  }

  Future<void> _run(){
    final task=_input.text.trim();
    if(task.isEmpty||_runtime.canCancel)return Future.value();
    _input.clear();
    setState((){
      _messages.add({'role':'user','text':task});
      _result=null;
    });
    _scrollEnd();
    return _runtime.run(task,approveReviewed:_approve).then((r){
      if(!mounted)return;
      setState((){
        _result=r;
        _messages.add({'role':'assistant','text':r.success?(r.report??'اكتملت المهمة بنجاح.'):'توقفت المهمة: '+(r.error??'خطأ غير معروف')});
      });
      _scrollEnd();
    });
  }

  void _scrollEnd()=>WidgetsBinding.instance.addPostFrameCallback((_){
    if(_scroll.hasClients)_scroll.animateTo(_scroll.position.maxScrollExtent,duration:const Duration(milliseconds:180),curve:Curves.easeOut);
  });

  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFF070B08),
    appBar:AppBar(
      backgroundColor:const Color(0xFF0B120E),
      title:const Row(children:[Icon(Icons.auto_awesome,color:Color(0xFF00FF41)),SizedBox(width:8),Text('Zion Super Agent')]),
      actions:[
        IconButton(onPressed:_runtime.canCancel?null:()=>setState((){
          _messages..clear()..add(const {'role':'assistant','text':'محادثة جديدة جاهزة. ما الذي تريد إنجازه؟'});
          _events.clear();_result=null;
        }),icon:const Icon(Icons.add_comment_outlined),tooltip:'محادثة جديدة'),
      ],
    ),
    body:Column(children:[
      _statusBar(),
      Expanded(child:ListView(
        controller:_scroll,
        padding:const EdgeInsets.fromLTRB(14,14,14,8),
        children:[
          for(final m in _messages)_message(m['role']!,m['text']!),
          if(_events.isNotEmpty)_activity(),
          if(_result!=null)_resultCard(),
          if(_runtime.canCancel)const LinearProgressIndicator(minHeight:2),
        ],
      )),
      _composer(),
    ]),
  );

  Widget _statusBar()=>Container(
    width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),color:const Color(0xFF0B120E),
    child:Wrap(spacing:8,runSpacing:6,children:[
      Chip(label:Text(_runtime.canApprove?'بانتظار الموافقة':_runtime.canCancel?'ينفذ الآن':'جاهز')),
      const Chip(label:Text('Local AI')),
      const Chip(label:Text('Tool-driven')),
      Row(mainAxisSize:MainAxisSize.min,children:[
        Switch.adaptive(value:_approve,onChanged:_runtime.canCancel?null:(v)=>setState(()=>_approve=v)),
        const Text('السماح بخطوات المراجعة',style:TextStyle(fontSize:11)),
      ]),
      if(_runtime.canApprove)...[
        IconButton.filled(onPressed:_runtime.approve,icon:const Icon(Icons.check,size:18),tooltip:'موافقة'),
        IconButton(onPressed:_runtime.deny,icon:const Icon(Icons.close,color:Colors.orangeAccent),tooltip:'رفض'),
      ],
      if(_runtime.canCancel)IconButton(onPressed:()=>_runtime.cancel(),icon:const Icon(Icons.stop_circle_outlined,color:Colors.redAccent),tooltip:'إلغاء'),
    ]),
  );

  Widget _message(String role,String text)=>Align(
    alignment:role=='user'?Alignment.centerRight:Alignment.centerLeft,
    child:Container(
      constraints:const BoxConstraints(maxWidth:760),
      margin:const EdgeInsets.only(bottom:10),
      padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(
        color:role=='user'?const Color(0xFF103D2A):const Color(0xFF101812),
        borderRadius:BorderRadius.circular(16),
        border:Border.all(color:const Color(0xFF00FF41).withOpacity(.12)),
      ),
      child:Text(text,style:const TextStyle(color:Colors.white70,height:1.45)),
    ),
  );

  Widget _activity()=>Card(
    color:const Color(0xFF0B120E),
    child:ExpansionTile(
      initiallyExpanded:true,
      leading:const Icon(Icons.timeline,color:Color(0xFF00FF41)),
      title:Text('نشاط الوكيل ('+_events.length.toString()+')'),
      children:[for(final e in _events)ListTile(
        dense:true,
        leading:Icon(_eventIcon(e),size:17,color:_eventColor(e)),
        title:Text(e.message,style:const TextStyle(fontSize:12,color:Colors.white70)),
        subtitle:Text(_stateLabel(e.state),style:const TextStyle(fontSize:10,color:Colors.white38)),
      )],
    ),
  );

  Widget _resultCard()=>Card(
    color:const Color(0xFF101812),
    child:Padding(
      padding:const EdgeInsets.all(14),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(_result!.success?Icons.task_alt:Icons.error_outline,color:_result!.success?Colors.greenAccent:Colors.redAccent),const SizedBox(width:8),const Text('النتيجة النهائية')]),
        const SizedBox(height:8),
        SelectableText(_result!.report??_result!.error??'لا توجد نتيجة.',style:const TextStyle(color:Colors.white70,height:1.4)),
      ]),
    ),
  );

  Widget _composer()=>SafeArea(
    child:Padding(
      padding:const EdgeInsets.fromLTRB(10,8,10,10),
      child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
        Expanded(child:TextField(
          enabled:!_runtime.canCancel,
          controller:_input,
          minLines:1,maxLines:5,
          onSubmitted:(_)=>_run(),
          style:const TextStyle(color:Colors.white),
          decoration:InputDecoration(
            hintText:'صف المهمة للوكيل… مثال: نفّذ الأمر pwd ثم اشرح النتيجة',
            hintStyle:const TextStyle(color:Colors.white38,fontSize:12),
            filled:true,fillColor:const Color(0xFF101812),
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none),
          ),
        )),
        const SizedBox(width:8),
        IconButton.filled(onPressed:_runtime.canCancel?null:_run,icon:const Icon(Icons.arrow_upward),tooltip:'إرسال'),
      ]),
    ),
  );

  IconData _eventIcon(AgentEvent e){
    if(e.message.contains('⛔')||e.message.contains('❌'))return Icons.block;
    if(e.message.contains('🔐'))return Icons.lock_outline;
    if(e.message.contains('✅'))return Icons.check_circle_outline;
    return Icons.bolt;
  }

  Color _eventColor(AgentEvent e){
    if(e.message.contains('⛔')||e.message.contains('❌'))return Colors.redAccent;
    if(e.message.contains('🔐'))return Colors.orangeAccent;
    if(e.message.contains('✅'))return Colors.greenAccent;
    return Colors.white54;
  }

  String _stateLabel(AgentState s)=>switch(s){
    AgentState.idle=>'جاهز',AgentState.planning=>'تخطيط',AgentState.executing=>'تنفيذ',
    AgentState.evaluating=>'تقييم',AgentState.waitingApproval=>'بانتظار الموافقة',
    AgentState.completed=>'اكتمل',AgentState.failed=>'فشل',AgentState.cancelled=>'أُلغي',
  };

  @override void dispose(){_sub?.cancel();_runtime.dispose();_input.dispose();_scroll.dispose();super.dispose();}
}
