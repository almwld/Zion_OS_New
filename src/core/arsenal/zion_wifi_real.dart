import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Real Wi-Fi security telemetry and assessment adapter.
///
/// This adapter never fabricates a successful security result. Native Wi-Fi
/// telemetry is collected through the Android platform channel and findings
/// are derived only from observed network properties.
class ZionWiFiReal {
  static final ZionWiFiReal _instance = ZionWiFiReal._internal();
  factory ZionWiFiReal() => _instance;
  ZionWiFiReal._internal();

  static const MethodChannel _channel = MethodChannel('zion.os/wifi');

  Future<List<WiFiNetworkObservation>> scanNetworks() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('scan');
      if (raw == null) return const <WiFiNetworkObservation>[];
      return raw
          .whereType<Map>()
          .map((item) => WiFiNetworkObservation.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false);
    } on PlatformException {
      rethrow;
    }
  }

  Future<WiFiConnectionObservation?> currentConnection() async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('connection');
      if (raw == null) return null;
      return WiFiConnectionObservation.fromMap(
        Map<String, dynamic>.from(raw),
      );
    } on PlatformException {
      rethrow;
    }
  }

  Future<WiFiSecurityAssessment> assessNetwork(
    WiFiNetworkObservation network,
  ) async {
    final findings = <WiFiSecurityFinding>[];
    final capabilities = network.capabilities.toUpperCase();

    final security = _classifySecurity(capabilities);
    if (security == WiFiSecurityMode.open) {
      findings.add(const WiFiSecurityFinding(
        id: 'wifi.open',
        severity: WiFiSeverity.critical,
        title: 'Open Wi-Fi network',
        description: 'The observed network advertises no WPA/WPA2/WPA3 protection.',
        recommendation: 'Use WPA3-Personal or WPA2-AES with a strong passphrase.',
      ));
    } else if (security == WiFiSecurityMode.legacyWep) {
      findings.add(const WiFiSecurityFinding(
        id: 'wifi.wep',
        severity: WiFiSeverity.critical,
        title: 'Legacy WEP security',
        description: 'WEP is cryptographically obsolete and should not be used.',
        recommendation: 'Migrate the access point to WPA2-AES or WPA3.',
      ));
    } else if (security == WiFiSecurityMode.wpa) {
      findings.add(const WiFiSecurityFinding(
        id: 'wifi.legacy-wpa',
        severity: WiFiSeverity.high,
        title: 'Legacy WPA security',
        description: 'The access point advertises legacy WPA protection.',
        recommendation: 'Disable legacy WPA/TKIP and use WPA2-AES or WPA3.',
      ));
    }

    if (capabilities.contains('WPS')) {
      findings.add(const WiFiSecurityFinding(
        id: 'wifi.wps-enabled',
        severity: WiFiSeverity.medium,
        title: 'WPS is advertised',
        description: 'WPS is enabled or advertised by the access point.',
        recommendation: 'Disable WPS when it is not required and prefer WPA2/WPA3.',
      ));
    }

    if (security == WiFiSecurityMode.wpa2 && capabilities.contains('TKIP')) {
      findings.add(const WiFiSecurityFinding(
        id: 'wifi.tkip',
        severity: WiFiSeverity.high,
        title: 'TKIP compatibility mode detected',
        description: 'TKIP is present in the advertised security configuration.',
        recommendation: 'Use AES/CCMP-only configuration.',
      ));
    }

    if (security == WiFiSecurityMode.wpa3) {
      findings.add(const WiFiSecurityFinding(
        id: 'wifi.wpa3',
        severity: WiFiSeverity.info,
        title: 'WPA3 advertised',
        description: 'The observed network advertises WPA3 protection.',
        recommendation: 'Keep WPA3 enabled and disable unnecessary legacy fallback.',
      ));
    }

    final signalScore = _signalScore(network.level);
    if (network.level <= -80) {
      findings.add(const WiFiSecurityFinding(
        id: 'wifi.weak-signal',
        severity: WiFiSeverity.low,
        title: 'Weak observed signal',
        description: 'The access point was observed with a weak RSSI.',
        recommendation: 'Investigate coverage and placement; weak signal alone is not a vulnerability.',
      ));
    }

    final risk = _riskScore(findings);
    return WiFiSecurityAssessment(
      network: network,
      securityMode: security,
      riskScore: risk,
      signalScore: signalScore,
      findings: findings,
      assessedAt: DateTime.now().toUtc(),
      source: 'REAL_WIFI_TELEMETRY',
    );
  }

  /// Performs a TCP connect scan against explicitly supplied ports.
  /// This is a defensive connectivity assessment and does not exploit services.
  Future<NetworkPortAssessment> scanTcpPorts(
    String host,
    Iterable<int> ports, {
    Duration timeout = const Duration(milliseconds: 900),
  }) async {
    final normalized = ports
        .where((port) => port > 0 && port <= 65535)
        .toSet()
        .toList()
      ..sort();
    final observations = <NetworkPortObservation>[];

    for (final port in normalized) {
      final started = DateTime.now();
      Socket? socket;
      try {
        socket = await Socket.connect(host, port, timeout: timeout);
        observations.add(NetworkPortObservation(
          port: port,
          state: NetworkPortState.open,
          latency: DateTime.now().difference(started),
        ));
      } on SocketException catch (error) {
        final state = error.osError?.errorCode == 111 ||
                error.osError?.errorCode == 61
            ? NetworkPortState.closed
            : NetworkPortState.filteredOrUnavailable;
        observations.add(NetworkPortObservation(
          port: port,
          state: state,
          latency: DateTime.now().difference(started),
          error: error.message,
        ));
      } catch (error) {
        observations.add(NetworkPortObservation(
          port: port,
          state: NetworkPortState.filteredOrUnavailable,
          latency: DateTime.now().difference(started),
          error: error.toString(),
        ));
      } finally {
        socket?.destroy();
      }
    }

    return NetworkPortAssessment(
      host: host,
      observations: observations,
      scannedAt: DateTime.now().toUtc(),
    );
  }

  // Legacy API names remain for source compatibility, but they are explicitly
  // blocked: these methods never attempt credential guessing, WPS PIN attacks,
  // credential capture, or rogue access-point phishing.
  Future<RouterHackResult> hackRouterDefaultCredentials(String routerIp) async {
    return RouterHackResult(
      routerIp: routerIp,
      blocked: true,
      error: 'Credential guessing is not an assessment capability.',
    );
  }

  Future<WPSHackResult> hackWPSPin(String bssid) async {
    return WPSHackResult(
      bssid: bssid,
      blocked: true,
      error: 'WPS PIN guessing is not an assessment capability.',
    );
  }

  Future<EvilTwinResult> evilTwinAttack(String targetSSID) async {
    return EvilTwinResult(
      targetSSID: targetSSID,
      blocked: true,
      error: 'Rogue access-point creation and credential capture are not supported.',
    );
  }

  Future<FullAttackResult> fullAttack(String target, {String? routerIp}) async {
    return FullAttackResult(
      target: target,
      success: false,
      method: 'DEFENSIVE_ASSESSMENT_REQUIRED',
      error: routerIp == null
          ? 'Use assessNetwork or scanTcpPorts for real defensive telemetry.'
          : 'Use defensive Wi-Fi and router assessment; credential attacks are disabled.',
    );
  }

  WiFiSecurityMode _classifySecurity(String capabilities) {
    if (capabilities.isEmpty || capabilities == '[ESS]') {
      return WiFiSecurityMode.open;
    }
    if (capabilities.contains('SAE') || capabilities.contains('WPA3')) {
      return WiFiSecurityMode.wpa3;
    }
    if (capabilities.contains('WEP')) return WiFiSecurityMode.legacyWep;
    if (capabilities.contains('WPA-') && !capabilities.contains('WPA2')) {
      return WiFiSecurityMode.wpa;
    }
    if (capabilities.contains('WPA2')) return WiFiSecurityMode.wpa2;
    return WiFiSecurityMode.unknown;
  }

  int _signalScore(int level) {
    if (level >= -50) return 100;
    if (level <= -100) return 0;
    return ((level + 100) * 2).clamp(0, 100);
  }

  int _riskScore(List<WiFiSecurityFinding> findings) {
    var score = 0;
    for (final finding in findings) {
      score += switch (finding.severity) {
        WiFiSeverity.critical => 40,
        WiFiSeverity.high => 25,
        WiFiSeverity.medium => 15,
        WiFiSeverity.low => 5,
        WiFiSeverity.info => 0,
      };
    }
    return score.clamp(0, 100);
  }
}

enum WiFiSecurityMode { open, legacyWep, wpa, wpa2, wpa3, unknown }
enum WiFiSeverity { info, low, medium, high, critical }
enum NetworkPortState { open, closed, filteredOrUnavailable }

class WiFiNetworkObservation {
  const WiFiNetworkObservation({
    required this.ssid,
    required this.bssid,
    required this.capabilities,
    required this.frequency,
    required this.level,
    required this.channelWidth,
  });

  factory WiFiNetworkObservation.fromMap(Map<String, dynamic> map) {
    return WiFiNetworkObservation(
      ssid: (map['ssid'] as String?) ?? '',
      bssid: (map['bssid'] as String?) ?? '',
      capabilities: (map['capabilities'] as String?) ?? '',
      frequency: (map['frequency'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? -100,
      channelWidth: (map['channelWidth'] as num?)?.toInt() ?? 0,
    );
  }

  final String ssid;
  final String bssid;
  final String capabilities;
  final int frequency;
  final int level;
  final int channelWidth;
}

class WiFiConnectionObservation {
  const WiFiConnectionObservation({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.linkSpeed,
    required this.frequency,
  });

  factory WiFiConnectionObservation.fromMap(Map<String, dynamic> map) {
    return WiFiConnectionObservation(
      ssid: (map['ssid'] as String?) ?? '',
      bssid: (map['bssid'] as String?) ?? '',
      rssi: (map['rssi'] as num?)?.toInt() ?? -100,
      linkSpeed: (map['linkSpeed'] as num?)?.toInt() ?? 0,
      frequency: (map['frequency'] as num?)?.toInt() ?? 0,
    );
  }

  final String ssid;
  final String bssid;
  final int rssi;
  final int linkSpeed;
  final int frequency;
}

class WiFiSecurityFinding {
  const WiFiSecurityFinding({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    required this.recommendation,
  });

  final String id;
  final WiFiSeverity severity;
  final String title;
  final String description;
  final String recommendation;
}

class WiFiSecurityAssessment {
  WiFiSecurityAssessment({
    required this.network,
    required this.securityMode,
    required this.riskScore,
    required this.signalScore,
    required List<WiFiSecurityFinding> findings,
    required this.assessedAt,
    required this.source,
  }) : findings = List.unmodifiable(findings);

  final WiFiNetworkObservation network;
  final WiFiSecurityMode securityMode;
  final int riskScore;
  final int signalScore;
  final List<WiFiSecurityFinding> findings;
  final DateTime assessedAt;
  final String source;
}

class NetworkPortObservation {
  const NetworkPortObservation({
    required this.port,
    required this.state,
    required this.latency,
    this.error,
  });

  final int port;
  final NetworkPortState state;
  final Duration latency;
  final String? error;
}

class NetworkPortAssessment {
  NetworkPortAssessment({
    required this.host,
    required List<NetworkPortObservation> observations,
    required this.scannedAt,
  }) : observations = List.unmodifiable(observations);

  final String host;
  final List<NetworkPortObservation> observations;
  final DateTime scannedAt;

  List<int> get openPorts => observations
      .where((item) => item.state == NetworkPortState.open)
      .map((item) => item.port)
      .toList(growable: false);
}

class RouterHackResult {
  const RouterHackResult({required this.routerIp, this.blocked = false, this.error});
  final String routerIp;
  final bool blocked;
  final String? error;
  bool get success => false;
}

class WPSHackResult {
  const WPSHackResult({required this.bssid, this.blocked = false, this.error});
  final String bssid;
  final bool blocked;
  final String? error;
  bool get success => false;
  int get attempts => 0;
}

class EvilTwinResult {
  const EvilTwinResult({required this.targetSSID, this.blocked = false, this.error});
  final String targetSSID;
  final bool blocked;
  final String? error;
  bool get success => false;
}

class FullAttackResult {
  const FullAttackResult({
    required this.target,
    required this.success,
    required this.method,
    this.error,
  });
  final String target;
  final bool success;
  final String method;
  final String? error;
}
