import '../core/window_manager.dart';
import '../models/window_id.dart';
class CloseWindow { const CloseWindow(this.manager); final WindowManager manager; bool call(WindowId id)=>manager.close(id); }