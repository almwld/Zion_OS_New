import '../models/app_window.dart';
import '../models/window_id.dart';
import '../models/window_state.dart';
class WindowFocusManager {
  WindowId? _active;
  WindowId? get activeWindowId=>_active;
  bool focus(AppWindow w){if(w.isClosed||w.isMinimized)return false;_active=w.id;w.state=WindowState.focused;return true;}
  bool activate(AppWindow w){if(w.isClosed||w.isMinimized)return false;_active=w.id;return true;}
  void clear()=>_active=null;
  void clearIf(WindowId id){if(_active==id)_active=null;}
}