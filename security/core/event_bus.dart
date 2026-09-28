import 'dart:async';

import 'security_event.dart';

class SecurityEventBus {
  SecurityEventBus() : _controller = StreamController<SecurityEvent>.broadcast();

  final StreamController<SecurityEvent> _controller;

  Stream<SecurityEvent> get stream => _controller.stream;

  bool get isClosed => _controller.isClosed;

  void publish(SecurityEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}
