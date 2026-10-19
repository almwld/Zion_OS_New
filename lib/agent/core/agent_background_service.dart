import 'package:flutter/services.dart';

/// Android foreground notification bridge for an active Super Agent task.
/// The foreground service keeps the app process important; the task itself
/// continues to run on the shared AgentRuntime in the Flutter engine.
class AgentBackgroundService {
  AgentBackgroundService._();

  static const MethodChannel _channel = MethodChannel('zion.os/agent_background');

  static Future<bool> start(String task) async {
    try {
      return await _channel.invokeMethod<bool>('start', <String, Object?>{
            'task': task.trim(),
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<bool>('stop');
    } on MissingPluginException {
      // Non-Android hosts and widget tests have no native service.
    } on PlatformException {
      // The agent result remains authoritative even if notification cleanup fails.
    }
  }
}
