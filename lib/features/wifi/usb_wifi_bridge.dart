import 'package:flutter/services.dart';

/// Intent bridge to USB WiFi Monitor's documented API.
class UsbWifiBridge {
  static const MethodChannel _channel = MethodChannel('zion.os/usbwifi');

  static Future<bool> isInstalled() async {
    final value = await _channel.invokeMethod<bool>('isInstalled');
    return value ?? false;
  }

  static Future<bool> startCapture({
    required int channel,
    required String pcapName,
  }) async {
    final value = await _channel.invokeMethod<bool>('startCapture', {
      'channel': channel,
      'pcapName': pcapName,
    });
    return value ?? false;
  }

  static Future<bool> stopCapture() async {
    final value = await _channel.invokeMethod<bool>('stopCapture');
    return value ?? false;
  }

  static Future<bool> openPcapFolder() async {
    final value = await _channel.invokeMethod<bool>('openPcapFolder');
    return value ?? false;
  }
}
