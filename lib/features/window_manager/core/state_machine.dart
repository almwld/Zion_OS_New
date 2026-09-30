import '../models/window_state.dart';
class WindowStateMachine {
  bool canTransition(WindowState from,WindowState to){
    if(from==to)return true;
    if(from==WindowState.closed)return false;
    if(to==WindowState.closed)return true;
    if(from==WindowState.minimized)return to==WindowState.focused||to==WindowState.maximized;
    if(from==WindowState.maximized)return to==WindowState.focused||to==WindowState.minimized;
    return to==WindowState.focused||to==WindowState.minimized||to==WindowState.maximized;
  }
}