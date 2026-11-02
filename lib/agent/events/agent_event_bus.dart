import 'dart:async';

import 'agent_event.dart';

/// ناقل أحداث مستقل لكل مهمة مع سجل قابل للاسترجاع.
class AgentEventBus {
  final StreamController<AgentEvent> _controller =
      StreamController<AgentEvent>.broadcast();
  final Map<String, List<AgentEvent>> _history = <String, List<AgentEvent>>{};
  bool _disposed = false;

  Stream<AgentEvent> get stream => _controller.stream;

  void emit(AgentEvent event) {
    if (_disposed) {
      throw StateError('لا يمكن بث أحداث بعد التخلص من AgentEventBus.');
    }
    _history.putIfAbsent(event.taskId, () => <AgentEvent>[]).add(event);
    _controller.add(event);
  }

  List<AgentEvent> getHistory(String taskId) =>
      List<AgentEvent>.unmodifiable(_history[taskId] ?? const []);

  void clearHistory(String taskId) => _history.remove(taskId);

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _controller.close();
    _history.clear();
  }
}
