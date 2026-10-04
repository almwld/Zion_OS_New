import 'package:flutter/widgets.dart';
import 'motion_tokens.dart';
class WindowAnimations {
  static Widget open({required Widget child,required Animation<double> animation})=>FadeTransition(
    opacity:CurvedAnimation(parent:animation,curve:MotionTokens.enter),
    child:ScaleTransition(scale:Tween(begin:.96,end:1.0).animate(animation),child:child),
  );
  static Widget close({required Widget child,required Animation<double> animation})=>FadeTransition(
    opacity:CurvedAnimation(parent:animation,curve:MotionTokens.exit),child:child,
  );
}
