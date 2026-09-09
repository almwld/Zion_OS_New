import 'package:flutter/services.dart';

/// Real Android platform data used by Zion OS UI/services.
///
/// This layer never fabricates device state. If Android cannot provide a value,
/// the call fails and the caller can present an unavailable state.
class ZionPlatformService {
  ZionPlatformService._();

  static const ZionPlatformService instance = ZionPlatformService._();
  static const MethodChannel _channel = MethodChannel('zion.os/platform');

  Future<Map<String, Object?>> getBatteryInfo() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('batteryInfo');
    return _normalize(result);
  }

  Future<Map<String, Object?>> getNetworkInfo() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('networkInfo');
    return _normalize(result);
  }

  Future<Map<String, Object?>> getStorageInfo() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('storageInfo');
    return _normalize(result);
  }

  Map<String, Object?> _normalize(Map<dynamic, dynamic>? value) {
    if (value == null) return const <String, Object?>{};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}
