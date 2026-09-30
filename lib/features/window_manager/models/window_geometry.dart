import 'package:flutter/foundation.dart';

@immutable
class WindowGeometry {
  const WindowGeometry({this.x=50,this.y=50,this.width=600,this.height=400});
  final double x,y,width,height;
  WindowGeometry copyWith({double? x,double? y,double? width,double? height}) => WindowGeometry(x:x??this.x,y:y??this.y,width:width??this.width,height:height??this.height);
  @override bool operator ==(Object other) => other is WindowGeometry && other.x==x && other.y==y && other.width==width && other.height==height;
  @override int get hashCode => Object.hash(x,y,width,height);
}