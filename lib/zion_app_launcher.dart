import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/window_manager/core/window_manager.dart';
import 'features/terminal/terminal_screen.dart';
import 'zion_browser.dart';
import 'zion_file_manager.dart';
import 'zion_system_monitor.dart';
import 'src/features/security_center/security_center.dart';
import 'ai/widgets/ai_chat_screen.dart';
import 'src/features/ai/advanced_ai_center.dart';
import 'agent/ui/agent_screen.dart';

class ZionAppLauncher extends StatefulWidget {
  const ZionAppLauncher({super.key});
  @override State<ZionAppLauncher> createState() => _ZionAppLauncherState();
}
class _ZionAppLauncherState extends State<ZionAppLauncher> {
  final _search = TextEditingController();
  final _apps = <_LauncherApp>[
    _LauncherApp('أدوات النظام','الطرفية',Icons.terminal,'Terminal',600,400),
    _LauncherApp('أدوات النظام','مدير الملفات',Icons.folder,'Files',600,400),
    _LauncherApp('أدوات النظام','محرر النصوص',Icons.edit,'Editor',600,450),
    _LauncherApp('أدوات النظام','متصفح Zion',Icons.language,'Browser',800,500),
    _LauncherApp('أدوات النظام','مراقب النظام',Icons.monitor,'Monitor',350,400),
    _LauncherApp('أدوات النظام','الذكاء المحلي Offline AI',Icons.psychology,'Offline AI',700,600),
    _LauncherApp('أدوات النظام','مركز الوكلاء والذكاء المتقدم',Icons.hub,'Zion AI Center',760,720),
    _LauncherApp('أدوات النظام','Zion Agent',Icons.smart_toy,'Zion Agent',820,700),
    _LauncherApp('الأمان والتشخيص','مركز الأمان',Icons.security,'Security',650,560),
  ];
  @override void dispose(){_search.dispose();super.dispose();}
  Widget _content(String title){
    switch(title){
      case 'Terminal': return const TerminalScreen();
      case 'Files': return const ZionFileManager();
      case 'Editor': return const _TextEditor();
      case 'Browser': return const ZionBrowser();
      case 'Monitor': return const ZionSystemMonitor();
      case 'Offline AI': return const AIChatScreen();
      case 'Zion AI Center': return const AdvancedAICenter();
      case 'Zion Agent': return const AgentScreen();
      case 'Security': return const SecurityCenter();
      default: return const SizedBox.shrink();
    }
  }
  @override Widget build(BuildContext context){
    final q=_search.text.trim().toLowerCase();
    final filtered=_apps.where((a)=>q.isEmpty||a.name.toLowerCase().contains(q)||a.title.toLowerCase().contains(q)).toList();
    return Container(width:400,height:500,decoration:BoxDecoration(color:const Color(0xFF0A0E0A),border:Border.all(color:const Color(0xFF00FF41).withOpacity(.5)),borderRadius:BorderRadius.circular(12)),
      child:Column(children:[
        Padding(padding:const EdgeInsets.all(12),child:TextField(controller:_search,onChanged:(_)=>setState((){}),style:const TextStyle(color:Colors.white,fontFamily:'monospace',fontSize:14),decoration:InputDecoration(hintText:'ابحث عن تطبيق...',hintStyle:TextStyle(color:Color(0x8000FF41)),prefixIcon:const Icon(Icons.search,color:Color(0xFF00FF41)),border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(8)))))),
        Expanded(child:ListView(padding:const EdgeInsets.all(8),children:[
          if(filtered.isEmpty) const Padding(padding:EdgeInsets.all(24),child:Center(child:Text('لا توجد تطبيقات مطابقة',style:TextStyle(color:Colors.white54)))),
          for(final group in ['أدوات النظام','الأمان والتشخيص'])
            if(filtered.any((a)=>a.category==group)) ...[
              _AppCategory(title:group),
              for(final a in filtered.where((a)=>a.category==group))
                _AppItem(icon:a.icon,name:a.name,onTap:()=>_openApp(context,a)),
            ],
        ])),
      ]));
  }
  void _openApp(BuildContext context,_LauncherApp app)=>context.read<WindowManager>().open(title:app.title,content:_content(app.title),width:app.width,height:app.height,appKey:app.title);
}
class _LauncherApp{const _LauncherApp(this.category,this.name,this.icon,this.title,this.width,this.height);final String category,name,title;final IconData icon;final double width,height;}
class _AppCategory extends StatelessWidget{const _AppCategory({required this.title});final String title;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(title,style:const TextStyle(color:Color(0xFF00FF41),fontSize:14,fontWeight:FontWeight.bold)));}
class _AppItem extends StatelessWidget{const _AppItem({required this.icon,required this.name,required this.onTap});final IconData icon;final String name;final VoidCallback onTap;@override Widget build(BuildContext context)=>ListTile(leading:Icon(icon,color:const Color(0xFF00FF41),size:22),title:Text(name,style:const TextStyle(color:Colors.white,fontSize:13)),dense:true,onTap:onTap);}
class _TextEditor extends StatefulWidget{const _TextEditor();@override State<_TextEditor> createState()=>_TextEditorState();}
class _TextEditorState extends State<_TextEditor>{final _controller=TextEditingController();@override void dispose(){_controller.dispose();super.dispose();}@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.all(12),child:TextField(controller:_controller,maxLines:null,expands:true,textAlignVertical:TextAlignVertical.top,decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'اكتب النص هنا...')));}
