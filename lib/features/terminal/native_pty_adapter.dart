import 'dart:async';

import 'package:flutter/services.dart';

class NativePtyAdapter {
  NativePtyAdapter()
      : _channel = const MethodChannel('zion.os/pty'),
        _events = const EventChannel('zion.os/pty/events');

  final MethodChannel _channel;
  final EventChannel _events;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<String> _output = StreamController<String>.broadcast();
  bool _running = false;

  Stream<String> get output => _output.stream;
  bool get isRunning => _running;

  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> start({int rows = 24, int cols = 80}) async {
    if (_running) return true;
    if (!await isAvailable()) return false;

    // Subscribe before creating the child so the first prompt/output is not lost.
    _subscription = _events.receiveBroadcastStream().listen(
      (dynamic value) {
        if (value != null) _output.add(value.toString());
      },
      onError: (Object error, StackTrace stack) {
        _output.add('[ZION] PTY event error: $error');
      },
    );

    try {
      await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'start',
        <String, Object>{'rows': rows, 'cols': cols},
      );
      _running = true;
      return true;
    } on PlatformException {
      await _subscription?.cancel();
      _subscription = null;
      _running = false;
      return false;
    }
  }

  Future<void> write(String input) async {
    if (!_running) return;
    try {
      await _channel.invokeMethod<void>('write', <String, Object>{'input': input});
    } on PlatformException {
      _running = false;
    }
  }

  Future<bool> resize({required int rows, required int cols}) async {
    if (!_running) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'resize',
            <String, Object>{'rows': rows, 'cols': cols},
          ) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stop() async {
    if (!_running) {
      await _subscription?.cancel();
      _subscription = null;
      return;
    }
    try {
      await _channel.invokeMethod<void>('stop');
    } finally {
      _running = false;
      await _subscription?.cancel();
      _subscription = null;
    }
  }

  Future<void> dispose() async {
    await stop();
    await _output.close();
  }
}
