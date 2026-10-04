import 'package:flutter/animation.dart';
class MotionTokens {
  static const fast=Duration(milliseconds:150);
  static const normal=Duration(milliseconds:250);
  static const slow=Duration(milliseconds:350);
  static const enter=Curves.easeOutCubic;
  static const exit=Curves.easeInCubic;
  static const switchWorkspace=Curves.easeInOutCubic;
}
