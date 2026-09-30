import '../models/app_window.dart';
import '../models/window_id.dart';
class WindowRegistry {
  final Map<WindowId,AppWindow> _windows={};
  Iterable<AppWindow> get all=>_windows.values;
  int get length=>_windows.length;
  AppWindow? get(WindowId id)=>_windows[id];
  bool add(AppWindow w){if(_windows.containsKey(w.id))return false;_windows[w.id]=w;return true;}
  AppWindow? remove(WindowId id)=>_windows.remove(id);
  void clear()=>_windows.clear();
}