import '../core/window_manager.dart';
import '../models/window_id.dart';
class FocusWindow { const FocusWindow(this.manager); final WindowManager manager; bool call(WindowId id)=>manager.focus(id); }