import 'package:flutter/services.dart';

class WifiScanner {
  static const MethodChannel _channel = MethodChannel('zion.os/wifi');

  /// Uses the Android WifiManager bridge so results come from the real device
  /// instead of attempting to invoke privileged shell commands from Dart.
  static Future<List<Map<String, dynamic>>> fullScan() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('scan');
      if (raw is! List) return <Map<String, dynamic>>[];

      final networks = raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      return _enrichNetworkData(networks);
    } on PlatformException {
      return <Map<String, dynamic>>[];
    }
  }

  static List<Map<String, dynamic>> _enrichNetworkData(
      List<Map<String, dynamic>> networks) {
    for (final network in networks) {
      final capabilities = network['capabilities']?.toString() ?? '';
      network['encryption'] = _detectEncryption(capabilities);
      network['is_open'] =
          capabilities.isNotEmpty &&
          capabilities.contains('ESS') &&
          !capabilities.contains('WPA') &&
          !capabilities.contains('WEP');
      network['wps_enabled'] = capabilities.contains('WPS');

      final signal = network['signal'];
      if (signal is num && signal < 0) {
        network['signal_percent'] =
            (100 + signal.toInt()).clamp(0, 100);
      } else if (signal is num) {
        network['signal_percent'] = signal.toInt().clamp(0, 100);
      }

      network['risk'] = network['is_open'] == true
          ? 'CRITICAL'
          : capabilities.contains('WEP')
              ? 'HIGH'
              : 'Low';
    }
    return networks;
  }

  static Future<Map<String, dynamic>> detailedScan(String bssid) async {
    final connection = await getCurrentConnection();
    if (connection['bssid']?.toString().toLowerCase() ==
        bssid.toLowerCase()) {
      return {'status': 'connected', 'info': connection};
    }
    return {
      'status': 'unavailable',
      'reason': 'Detailed telemetry for this BSSID is not exposed by Android.',
    };
  }

  static Future<Map<String, dynamic>> getCurrentConnection() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('connection');
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } on PlatformException {
      // The native bridge reports permission/unavailability through its
      // scan response; connection telemetry may simply be unavailable.
    }
    return {'connected': false, 'status': 'UNAVAILABLE'};
  }

  static String _detectEncryption(String capabilities) {
    final lower = capabilities.toLowerCase();
    if (lower.contains('wpa3')) return 'WPA3';
    if (lower.contains('wpa2')) return 'WPA2';
    if (lower.contains('wpa')) return 'WPA';
    if (lower.contains('wep')) return 'WEP';
    if (lower.contains('ess')) return 'Open';
    return 'Unknown';
  }
}
