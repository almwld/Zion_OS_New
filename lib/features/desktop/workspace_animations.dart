import 'package:flutter/widgets.dart';
import 'motion_tokens.dart';
class WorkspaceAnimations {
  static Widget switchTo({required Widget child,required Animation<double> animation})=>SlideTransition(
    position:Tween(begin:const Offset(.08,0),end:Offset.zero).animate(CurvedAnimation(parent:animation,curve:MotionTokens.switchWorkspace)),
    child:FadeTransition(opacity:animation,child:child),
  );
}
