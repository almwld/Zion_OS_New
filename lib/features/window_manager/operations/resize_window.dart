import '../core/window_manager.dart';
import '../models/window_id.dart';
import '../models/window_resize_edge.dart';
class ResizeWindow {
  const ResizeWindow(this.manager);
  final WindowManager manager;
  bool call(WindowId id, WindowResizeEdge edge, double deltaX, double deltaY)=>manager.resize(id, edge, deltaX, deltaY);
}