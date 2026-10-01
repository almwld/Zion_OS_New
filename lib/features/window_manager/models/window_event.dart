import 'window_id.dart';
enum WindowEventType { opened, closed, focused, raised, minimized, maximized, snapped }
class WindowEvent {
  const WindowEvent(this.type,this.windowId);
  final WindowEventType type;
  final WindowId windowId;
}