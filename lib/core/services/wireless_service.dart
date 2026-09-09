import '../services/zion_platform_service.dart';

/// Wi-Fi state exposed by Android without privileged or shell access.
///
/// Scanning and joining protected networks are intentionally not simulated.
/// A production implementation should use Android's user-approved Wi-Fi APIs
/// when that capability is explicitly required.
class WirelessService {
  static final WirelessService _instance = WirelessService._internal();
  factory WirelessService() => _instance;
  WirelessService._internal();

  final ZionPlatformService _platform = ZionPlatformService.instance;
  List<Map<String, String>> _wifiNetworks = const <Map<String, String>>[];
  List<Map<String, String>> _savedNetworks = const <Map<String, String>>[];
  bool _isScanning = false;

  Future<void> init() async {}

  Future<void> scanWiFiNetworks() async {
    _isScanning = true;
    try {
      final info = await _platform.getNetworkInfo();
      final transport = info['transport']?.toString();
      final connected = info['connected'] == true;
      if (transport == 'wifi' && connected) {
        _wifiNetworks = <Map<String, String>>[
          {
            'ssid': 'الشبكة الحالية',
            'signal': 'غير متاح',
            'security': 'غير متاح',
            'bssid': 'غير متاح',
            'channel': 'غير متاح',
          },
        ];
      } else {
        _wifiNetworks = const <Map<String, String>>[];
      }
    } catch (_) {
      _wifiNetworks = const <Map<String, String>>[];
    } finally {
      _isScanning = false;
    }
  }

  /// Returns false instead of pretending a network was joined. Android Wi-Fi
  /// configuration must be performed through an approved system flow.
  Future<bool> connectToWiFi(String ssid, String password) async {
    return false;
  }

  Future<void> forgetNetwork(String ssid) async {
    _savedNetworks = List<Map<String, String>>.from(_savedNetworks)
      ..removeWhere((network) => network['ssid'] == ssid);
  }

  Future<String?> getCurrentWiFiName() async {
    try {
      final info = await _platform.getNetworkInfo();
      return info['transport']?.toString() == 'wifi' ? 'الشبكة الحالية' : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getCurrentIP() async {
    try {
      final info = await _platform.getNetworkInfo();
      return info['ipAddress']?.toString();
    } catch (_) {
      return null;
    }
  }

  List<Map<String, String>> get wifiNetworks => List.unmodifiable(_wifiNetworks);
  List<Map<String, String>> get savedNetworks => List.unmodifiable(_savedNetworks);
  bool get isScanning => _isScanning;
}
