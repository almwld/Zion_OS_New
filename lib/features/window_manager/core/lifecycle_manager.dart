import '../models/app_window.dart';
import '../models/window_state.dart';
import 'state_machine.dart';
class WindowLifecycleManager {
  WindowLifecycleManager(this._machine);
  final WindowStateMachine _machine;
  bool transition(AppWindow w,WindowState next){if(!_machine.canTransition(w.state,next))return false;w.state=next;return true;}
}