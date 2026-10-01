import 'package:flutter/material.dart';
import '../features/window_manager/core/window_manager.dart';
import '../features/window_manager/models/window_id.dart';

class AltTabOverlay extends StatelessWidget {
  const AltTabOverlay({super.key,required this.manager,required this.selectedId});
  final WindowManager manager;
  final WindowId? selectedId;

  @override
  Widget build(BuildContext context) {
    final windows=manager.visibleWindows.reversed.toList(growable:false);
    if(windows.length<2) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth:720,maxHeight:220),
            margin: const EdgeInsets.symmetric(horizontal:24),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(.55)),
              boxShadow: const [BoxShadow(color:Colors.black54,blurRadius:30)],
            ),
            child: Column(mainAxisSize:MainAxisSize.min,children:[
              const Row(mainAxisSize:MainAxisSize.min,children:[
                Icon(Icons.swap_horiz,color:Color(0xFF00BCD4),size:18),
                SizedBox(width:8),
                Text('ALT + TAB',style:TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.bold,letterSpacing:1.2)),
              ]),
              const SizedBox(height:12),
              SingleChildScrollView(
                scrollDirection:Axis.horizontal,
                child: Row(mainAxisSize:MainAxisSize.min,children:windows.map((window){
                  final selected=window.id==selectedId;
                  return Container(
                    width:150,height:120,margin:const EdgeInsets.symmetric(horizontal:5),padding:const EdgeInsets.all(8),
                    decoration:BoxDecoration(
                      color:selected?const Color(0xFF00BCD4).withOpacity(.16):Colors.white.withOpacity(.05),
                      borderRadius:BorderRadius.circular(14),
                      border:Border.all(color:selected?const Color(0xFF00E5FF):Colors.white24,width:selected?2:1),
                    ),
                    child:Column(children:[
                      Expanded(child:ClipRRect(
                        borderRadius:BorderRadius.circular(8),
                        child:ColoredBox(color:Colors.black54,child:FittedBox(fit:BoxFit.contain,child:IgnorePointer(child:window.content))),
                      )),
                      const SizedBox(height:6),
                      Text(window.title,maxLines:1,overflow:TextOverflow.ellipsis,
                        style:TextStyle(color:selected?const Color(0xFF00E5FF):Colors.white70,fontSize:11,fontWeight:selected?FontWeight.bold:FontWeight.normal)),
                    ]),
                  );
                }).toList()),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
