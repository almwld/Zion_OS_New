import 'package:flutter/foundation.dart';

import 'core/services/zion_platform_service.dart';

class NetworkInterface {
  final String name;
  final String type;
  final String status;
  final String ipAddress;
  final String macAddress;
  final int signalStrength;
  final double txSpeed;
  final double rxSpeed;

  const NetworkInterface({
    required this.name,
    required this.type,
    required this.status,
    required this.ipAddress,
    required this.macAddress,
    this.signalStrength = 0,
    this.txSpeed = 0,
    this.rxSpeed = 0,
  });
}

/// Network state reported by Android. No interface, address, VPN, Tor, or
/// firewall state is fabricated when Android cannot expose it to an app.
class ZionNetworkManager extends ChangeNotifier {
  ZionNetworkManager({ZionPlatformService? platform})
      : _platform = platform ?? ZionPlatformService.instance {
    refresh();
  }

  final ZionPlatformService _platform;
  List<NetworkInterface> _interfaces = const <NetworkInterface>[];
  bool _available = false;
  bool _vpnEnabled = false;
  bool _torEnabled = false;
  bool _firewallEnabled = false;
  bool _dnsOverHttps = false;
  bool _isRefreshing = false;

  List<NetworkInterface> get interfaces => _interfaces;
  bool get available => _available;
  bool get vpnEnabled => _vpnEnabled;
  bool get torEnabled => _torEnabled;
  bool get firewallEnabled => _firewallEnabled;
  bool get dnsOverHttps => _dnsOverHttps;
  bool get isRefreshing => _isRefreshing;

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      final info = await _platform.getNetworkInfo();
      _available = info['available'] == true;
      final transport = info['transport']?.toString() ?? 'none';
      final connected = info['connected'] == true;
      final validated = info['validated'] == true;
      final ip = info['ipAddress']?.toString() ?? 'غير متاح';

      if (!_available) {
        _interfaces = const <NetworkInterface>[];
      } else {
        _interfaces = <NetworkInterface>[
          NetworkInterface(
            name: transport == 'none' ? 'network' : transport,
            type: transport,
            status: connected ? (validated ? 'connected' : 'limited') : 'disconnected',
            ipAddress: ip,
            macAddress: 'غير متاح',
          ),
        ];
      }
      _vpnEnabled = info['vpn'] == true;
    } catch (_) {
      _available = false;
      _interfaces = const <NetworkInterface>[];
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// A regular Android application cannot silently join a protected Wi-Fi
  /// network. Wi-Fi configuration must use Android's user-approved APIs.
  Future<bool> connectToWiFi(String ssid, String password) async {
    if (ssid.trim().isEmpty || password.isEmpty) return false;
    return false;
  }

  /// These flags are local UI policy only; they do not claim to enable a
  /// system VPN, Tor daemon, firewall, or DNS-over-HTTPS provider.
  void setVpnPolicy(bool enabled) {
    _vpnEnabled = enabled;
    notifyListeners();
  }

  void setTorPolicy(bool enabled) {
    _torEnabled = enabled;
    notifyListeners();
  }

  void setFirewallPolicy(bool enabled) {
    _firewallEnabled = enabled;
    notifyListeners();
  }

  void setDnsOverHttpsPolicy(bool enabled) {
    _dnsOverHttps = enabled;
    notifyListeners();
  }
}
