import 'package:flutter/widgets.dart';
import 'window_constraints.dart';
import 'window_geometry.dart';
import 'window_id.dart';
import 'window_state.dart';

class AppWindow {
  AppWindow({required this.id,required this.title,required this.content,this.geometry=const WindowGeometry(),this.constraints=const WindowConstraints(),this.state=WindowState.created,this.workspace=0,this.zIndex=0,this.appKey});
  final WindowId id;
  final String title;
  final Widget content;
  WindowGeometry geometry;
  final WindowConstraints constraints;
  WindowState state;
  int workspace;
  int zIndex;
  final String? appKey;
  bool get isClosed => state==WindowState.closed;
  bool get isMinimized => state==WindowState.minimized;
  bool get isMaximized => state==WindowState.maximized;
}