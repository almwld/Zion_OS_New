import 'dart:async';

class CancellationToken {
  bool _cancelled = false;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  bool get isCancelled => _cancelled;
  Stream<void> get onCancel => _controller.stream;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _controller.add(null);
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const AgentCancelledException();
    }
  }

  Future<void> dispose() => _controller.close();
}

class AgentCancelledException implements Exception {
  const AgentCancelledException();

  @override
  String toString() => 'Agent execution cancelled.';
}
