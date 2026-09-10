import 'dart:io';

class WifiScanner {
  /// Returns only Wi-Fi telemetry actually obtained from the runtime.
  /// Unsupported shell/platform access is reported as unavailable, never mocked.
  static Future<List<Map<String, dynamic>>> fullScan() async {
    final networks = <Map<String, dynamic>>[];
    try {
      final result = await Process.run('cmd', ['wifi', 'scan-results'], runInShell: true);
      if (result.exitCode == 0) networks.addAll(_parseAndroidWifiOutput(result.stdout.toString()));
    } catch (_) {}
    return _enrichNetworkData(networks);
  }

  static List<Map<String, dynamic>> _parseAndroidWifiOutput(String output) {
    final networks = <Map<String, dynamic>>[];
    var started = false;
    for (final line in output.split('\n')) {
      if (line.toLowerCase().contains('bssid')) { started = true; continue; }
      if (!started || line.trim().isEmpty) continue;
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 4 || !RegExp(r'^[0-9a-fA-F:]{17}$').hasMatch(parts[0])) continue;
      final signal = int.tryParse(parts[2].replaceAll(RegExp(r'[^0-9-]'), ''));
      networks.add({
        'bssid': parts[0],
        'frequency': parts[1],
        'signal': signal ?? 0,
        'ssid': parts.length > 4 ? parts.sublist(3).join(' ') : parts[3],
        'channel': _frequencyToChannel(parts[1]),
      });
    }
    return networks;
  }

  static List<Map<String, dynamic>> _enrichNetworkData(List<Map<String, dynamic>> networks) {
    for (final network in networks) {
      final capabilities = network['capabilities']?.toString() ?? '';
      network['encryption'] = _detectEncryption(capabilities);
      network['is_open'] = capabilities.isNotEmpty && capabilities.contains('ESS') && !capabilities.contains('WPA');
      network['wps_enabled'] = capabilities.contains('WPS');
      final signal = network['signal'];
      if (signal is int && signal < 0) network['signal_percent'] = (100 + signal).clamp(0, 100);
      else if (signal is int) network['signal_percent'] = signal.clamp(0, 100);
      network['risk'] = network['is_open'] == true ? 'CRITICAL' : (capabilities.contains('WEP') ? 'HIGH' : 'Low');
    }
    return networks;
  }

  static Future<Map<String, dynamic>> detailedScan(String bssid) async {
    final connection = await getCurrentConnection();
    if (connection['bssid'] == bssid) return {'status': 'connected', 'info': connection};
    return {'status': 'unavailable', 'reason': 'Detailed Wi-Fi telemetry is not exposed by this runtime.'};
  }

  static Future<Map<String, dynamic>> getCurrentConnection() async {
    try {
      final result = await Process.run('cmd', ['wifi', 'status'], runInShell: true);
      if (result.exitCode == 0) return _parseCurrentConnection(result.stdout.toString());
    } catch (_) {}
    return {'connected': false, 'status': 'UNAVAILABLE'};
  }

  static Map<String, dynamic> _parseCurrentConnection(String output) {
    final info = <String, dynamic>{'connected': false};
    final ssid = RegExp(r'SSID:\s*"([^"]*)"', caseSensitive: false).firstMatch(output)?.group(1);
    final bssid = RegExp(r'BSSID:\s*([0-9a-fA-F:]{17})', caseSensitive: false).firstMatch(output)?.group(1);
    if (ssid != null && ssid.isNotEmpty) { info['connected'] = true; info['ssid'] = ssid; info['bssid'] = bssid; }
    return info;
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

  static String _frequencyToChannel(String value) {
    final freq = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (freq >= 2412 && freq <= 2484) return ((freq - 2407) / 5).round().toString();
    if (freq >= 5170 && freq <= 5825) return ((freq - 5000) / 5).round().toString();
    return 'Unknown';
  }
}
