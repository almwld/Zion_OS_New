import '../core/window_manager.dart';
import '../models/window_id.dart';
class RaiseWindow { const RaiseWindow(this.manager); final WindowManager manager; bool call(WindowId id)=>manager.raise(id); }