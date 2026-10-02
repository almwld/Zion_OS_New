import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class NativePtyAdapter {
  NativePtyAdapter() : _channel = const MethodChannel('zion.os/pty');

  static final Stream<dynamic> _sharedEvents =
      const EventChannel('zion.os/pty/events').receiveBroadcastStream();

  final MethodChannel _channel;
  StreamSubscription<dynamic>? _subscription;
  final StreamController<String> _output = StreamController<String>.broadcast();
  final StreamController<List<int>> _rawBytes =
      StreamController<List<int>>.broadcast();
  StreamSubscription<String>? _decoderSubscription;
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

  Future<bool> start({int rows = 24, int cols = 80, String? shell}) async {
    if (_running) return true;
    if (!await isAvailable()) return false;

    _decoderSubscription ??= _rawBytes
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(_output.add);

    _subscription ??= _sharedEvents.listen(
      (dynamic value) {
        if (value is! Map) return;
        final id = value['sessionId'];
        if (id != _handle) return;
        if (value['closed'] == true) {
          _running = false;
          return;
        }
        final data = value['data'];
        if (data is Uint8List) {
          _rawBytes.add(data);
        } else if (data is List<int>) {
          _rawBytes.add(data);
        }
      },
      onError: (Object error, StackTrace stack) {
        _output.add('[ZION] PTY event error: $error');
      },
    );

    try {
      final handle = await _channel.invokeMethod<int>(
        'start',
        <String, Object>{
          'rows': rows,
          'cols': cols,
          if (shell != null && shell.trim().isNotEmpty) 'shell': shell.trim(),
        },
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

  Future<void> write(String input) =>
      writeBytes(Uint8List.fromList(utf8.encode(input)));

  Future<void> writeBytes(Uint8List bytes) async {
    final handle = _handle;
    if (!_running || handle == null || bytes.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('write', <String, Object>{
        'handle': handle,
        'input': bytes,
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
        await _channel.invokeMethod<void>(
          'stop',
          <String, Object>{'handle': handle},
        );
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await stop();
    await _subscription?.cancel();
    _subscription = null;
    await _decoderSubscription?.cancel();
    _decoderSubscription = null;
    await _rawBytes.close();
    await _output.close();
  }
}
