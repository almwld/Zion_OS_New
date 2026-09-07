import 'dart:convert';

/// Defensive analysis primitives for authorized lab captures and requests.
///
/// These routines analyze evidence supplied by the caller. They do not emit
/// deauthentication frames, brute-force WPS, create rogue APs, capture
/// credentials, or execute SQL injection against a target.
class DefensiveAttackLab {
  const DefensiveAttackLab();

  WiFiRogueApReport detectEvilTwinPatterns(
    Iterable<WiFiObservation> observations,
  ) {
    final bySsid = <String, List<WiFiObservation>>{};
    for (final item in observations) {
      final key = item.ssid.trim();
      if (key.isEmpty) continue;
      bySsid.putIfAbsent(key, () => <WiFiObservation>[]).add(item);
    }

    final findings = <WiFiRogueApFinding>[];
    bySsid.forEach((ssid, aps) {
      final bssids = aps.map((e) => e.bssid.toLowerCase()).toSet();
      final security = aps.map((e) => e.security.toUpperCase()).toSet();
      if (bssids.length > 1 && security.length > 1) {
        findings.add(WiFiRogueApFinding(
          ssid: ssid,
          reason: 'Same SSID observed with multiple BSSIDs and different security advertisements.',
          severity: 'HIGH',
        ));
      } else if (bssids.length > 1) {
        findings.add(WiFiRogueApFinding(
          ssid: ssid,
          reason: 'Same SSID observed from multiple BSSIDs; verify against the authorized AP inventory.',
          severity: 'MEDIUM',
        ));
      }
    });
    return WiFiRogueApReport(findings: findings);
  }

  DeauthDetectionReport detectDeauthBurst(
    Iterable<WiFiManagementFrame> frames, {
    int threshold = 20,
  }) {
    final counts = <String, int>{};
    for (final frame in frames) {
      if (frame.type != WiFiManagementFrameType.deauth &&
          frame.type != WiFiManagementFrameType.disassoc) {
        continue;
      }
      final key = '${frame.bssid.toLowerCase()}|${frame.windowStart.toUtc().millisecondsSinceEpoch}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final alerts = <DeauthBurstAlert>[];
    counts.forEach((key, count) {
      if (count < threshold) return;
      final separator = key.indexOf('|');
      alerts.add(DeauthBurstAlert(
        bssid: key.substring(0, separator),
        count: count,
        threshold: threshold,
      ));
    });
    return DeauthDetectionReport(alerts: alerts);
  }

  /// Detects SQLi-like input in already-collected application logs/requests.
  /// It performs no request to the target and never extracts database data.
  SqlInjectionDetectionReport inspectRequest(String rawRequest) {
    final decoded = Uri.decodeComponent(rawRequest);
    final normalized = decoded.toLowerCase();
    final indicators = <String>[];
    final patterns = <String, RegExp>{
      'tautology': RegExp(r"(?:'|%27)\s*(?:or|and)\s+\d+\s*=\s*\d+", caseSensitive: false),
      'union': RegExp(r"\bunion\s+(?:all\s+)?select\b", caseSensitive: false),
      'comment': RegExp(r"(?:--|/\*|\*/|#)", caseSensitive: false),
      'stacked-query': RegExp(r";\s*(?:select|insert|update|delete|drop|alter|create)\b", caseSensitive: false),
    };
    patterns.forEach((name, pattern) {
      if (pattern.hasMatch(decoded) || pattern.hasMatch(normalized)) {
        indicators.add(name);
      }
    });
    return SqlInjectionDetectionReport(
      suspicious: indicators.isNotEmpty,
      indicators: indicators,
      evidenceSha256: _sha256Placeholder(rawRequest),
    );
  }

  String _sha256Placeholder(String value) {
    // Stable evidence identifier without transmitting or executing the input.
    return base64Url.encode(utf8.encode(value)).substring(0, 16);
  }
}

class WiFiObservation {
  const WiFiObservation({required this.ssid, required this.bssid, required this.security});
  final String ssid;
  final String bssid;
  final String security;
}

class WiFiRogueApFinding {
  const WiFiRogueApFinding({required this.ssid, required this.reason, required this.severity});
  final String ssid;
  final String reason;
  final String severity;
}

class WiFiRogueApReport {
  const WiFiRogueApReport({required this.findings});
  final List<WiFiRogueApFinding> findings;
  bool get suspicious => findings.isNotEmpty;
}

enum WiFiManagementFrameType { deauth, disassoc, beacon, probe, other }

class WiFiManagementFrame {
  const WiFiManagementFrame({required this.type, required this.bssid, required this.windowStart});
  final WiFiManagementFrameType type;
  final String bssid;
  final DateTime windowStart;
}

class DeauthBurstAlert {
  const DeauthBurstAlert({required this.bssid, required this.count, required this.threshold});
  final String bssid;
  final int count;
  final int threshold;
}

class DeauthDetectionReport {
  const DeauthDetectionReport({required this.alerts});
  final List<DeauthBurstAlert> alerts;
  bool get suspicious => alerts.isNotEmpty;
}

class SqlInjectionDetectionReport {
  const SqlInjectionDetectionReport({required this.suspicious, required this.indicators, required this.evidenceSha256});
  final bool suspicious;
  final List<String> indicators;
  final String evidenceSha256;
}
