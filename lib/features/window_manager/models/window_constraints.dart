import 'package:flutter/foundation.dart';

@immutable
class WindowConstraints {
  const WindowConstraints({this.minWidth=240,this.minHeight=180,this.maxWidth=double.infinity,this.maxHeight=double.infinity});
  final double minWidth,minHeight,maxWidth,maxHeight;
  WindowConstraints normalized() => WindowConstraints(minWidth:minWidth.clamp(0,maxWidth),minHeight:minHeight.clamp(0,maxHeight),maxWidth:maxWidth,maxHeight:maxHeight);
}