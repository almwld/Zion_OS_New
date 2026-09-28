import 'dart:async';
import 'package:flutter/services.dart';

/// Real Android bridge for the Zion/Termux-compatible device API surface.
/// Methods return explicit UNAVAILABLE/PERMISSION_REQUIRED states instead of
/// silently emulating functionality when Android cannot provide it.
class TermuxApi {
  static const TermuxApi instance = TermuxApi._();
  const TermuxApi._();

  static const MethodChannel _channel = MethodChannel('zion.os/termux');

  Future<Map<String, Object?>> setupStorage() => _map('setup-storage');
  Future<Map<String, Object?>> batteryStatus() => _map('battery');
  Future<Map<String, Object?>> camera() => _map('camera');

  Future<Map<String, Object?>> clipboardGet() => _map('clipboard-get');
  Future<Map<String, Object?>> clipboardSet(String text) =>
      _map('clipboard-set', <String, Object?>{'text': text});

  Future<Map<String, Object?>> dialog({
    required String title,
    required String message,
    String positive = 'OK',
    String negative = 'Cancel',
  }) =>
      _map('dialog', <String, Object?>{
        'title': title,
        'message': message,
        'positive': positive,
        'negative': negative,
      });

  Future<Map<String, Object?>> fingerprint() => _map('fingerprint');
  Future<Map<String, Object?>> location() => _map('location');

  Future<Map<String, Object?>> notification({
    required String title,
    required String content,
    String channelId = 'zion_default',
  }) =>
      _map('notification', <String, Object?>{
        'title': title,
        'content': content,
        'channelId': channelId,
      });

  Future<Map<String, Object?>> sensor({int sensorType = 1}) =>
      _map('sensor', <String, Object?>{'sensorType': sensorType});

  Future<Map<String, Object?>> sms({
    required String number,
    String? body,
  }) =>
      _map('sms', <String, Object?>{
        'number': number,
        if (body != null) 'body': body,
      });

  Future<Map<String, Object?>> toast(String text) =>
      _map('toast', <String, Object?>{'text': text});

  Future<Map<String, Object?>> tts(String text) =>
      _map('tts', <String, Object?>{'text': text});

  Future<Map<String, Object?>> vibrate({int durationMs = 250}) =>
      _map('vibrate', <String, Object?>{'durationMs': durationMs});

  Future<Map<String, Object?>> wakeLock({required bool enabled}) =>
      _map('wake-lock', <String, Object?>{'enabled': enabled});

  Future<Map<String, Object?>> _map(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      final value = await _channel.invokeMethod<Object?>(method, arguments);
      if (value is Map) {
        return Map<String, Object?>.from(value);
      }
      return <String, Object?>{
        'available': false,
        'status': 'UNAVAILABLE',
        'reason': 'Android bridge returned no result.',
      };
    } on MissingPluginException {
      return <String, Object?>{
        'available': false,
        'status': 'UNAVAILABLE',
        'reason': 'Android Termux API bridge is not installed.',
      };
    } on PlatformException catch (e) {
      return <String, Object?>{
        'available': false,
        'status': e.code == 'PERMISSION_REQUIRED'
            ? 'PERMISSION_REQUIRED'
            : 'UNAVAILABLE',
        'reason': e.message ?? e.code,
      };
    }
  }
}
