import 'package:flutter/widgets.dart';
import '../core/window_manager.dart';
import '../models/window_id.dart';
class OpenWindow {
  const OpenWindow(this.manager);
  final WindowManager manager;
  WindowId call({required String title,required Widget content,double width=600,double height=400,int workspace=0,String? appKey})=>manager.open(title:title,content:content,width:width,height:height,workspace:workspace,appKey:appKey);
}