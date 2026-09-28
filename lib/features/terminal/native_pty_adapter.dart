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
  int? _handle;
  bool _running = false;

  Stream<String> get output => _output.stream;
  bool get isRunning => _running;
  int? get handle => _handle;

  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> start({int rows = 24, int cols = 80}) async {
    if (_running) return true;
    if (!await isAvailable()) return false;

    _subscription ??= _events.receiveBroadcastStream().listen(
      (dynamic value) {
        if (value is Map) {
          final id = value['sessionId'];
          if (id == _handle && value['data'] != null) {
            _output.add(value['data'].toString());
          }
          if (id == _handle && value['closed'] == true) {
            _running = false;
          }
        }
      },
      onError: (Object error, StackTrace stack) {
        _output.add('[ZION] PTY event error: $error');
      },
    );

    try {
      final handle = await _channel.invokeMethod<int>(
        'start',
        <String, Object>{'rows': rows, 'cols': cols},
      );
      if (handle == null || handle <= 0) {
        await stop();
        return false;
      }
      _handle = handle;
      _running = true;
      return true;
    } on PlatformException {
      await stop();
      return false;
    } on MissingPluginException {
      await stop();
      return false;
    }
  }

  Future<void> write(String input) async {
    final handle = _handle;
    if (!_running || handle == null) return;
    try {
      await _channel.invokeMethod<void>('write', <String, Object>{
        'handle': handle,
        'input': input,
      });
    } on PlatformException {
      _running = false;
    } on MissingPluginException {
      _running = false;
    }
  }

  Future<bool> resize({required int rows, required int cols}) async {
    final handle = _handle;
    if (!_running || handle == null) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'resize',
            <String, Object>{'handle': handle, 'rows': rows, 'cols': cols},
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> stop() async {
    final handle = _handle;
    _handle = null;
    _running = false;
    if (handle != null) {
      try {
        await _channel.invokeMethod<void>('stop', <String, Object>{'handle': handle});
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await stop();
    await _subscription?.cancel();
    _subscription = null;
    await _output.close();
  }
}
