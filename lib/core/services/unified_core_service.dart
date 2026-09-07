import 'dart:io';

import 'package:flutter/foundation.dart';

/// Defensive, runtime-safe system diagnostics used by the UI.
/// Offensive tool execution, credential attacks and exploitation are not
/// exposed through this production service.
class UnifiedCoreService {
  Future<String> execute(String command, {String? target, Map<String, String>? options}) async {
    try {
      switch (command) {
        case 'help':
          return _helpText();
        case 'system_info':
          return _systemInfo();
        case 'dns_lookup':
          return _dnsLookup(target ?? 'localhost');
        case 'ping':
          return _ping(target ?? '127.0.0.1');
        case 'ssl_check':
          return _sslCheck(target ?? 'google.com');
        case 'http_headers':
          return _httpHeaders(target ?? 'https://google.com');
        case 'network_info':
          return 'Network diagnostics are available through the platform network services.';
        case 'port_scan':
          return 'Port scanning is intentionally disabled in the production command surface.';
        default:
          return 'Command unavailable in production: $command';
      }
    } catch (e) {
      return 'Diagnostic error: $e';
    }
  }

  Future<String> _ping(String host) async {
    if (!_isSafeHost(host)) return 'Invalid host.';
    try {
      final result = await Process.run('ping', ['-c', '1', '-W', '1', host], runInShell: false).timeout(const Duration(seconds: 3));
      return result.stdout.toString().trim().isEmpty ? result.stderr.toString().trim() : result.stdout.toString().trim();
    } catch (e) {
      return 'Ping unavailable on this runtime: $e';
    }
  }

  Future<String> _dnsLookup(String host) async {
    if (!_isSafeHost(host)) return 'Invalid host.';
    try {
      final addresses = await InternetAddress.lookup(host).timeout(const Duration(seconds: 5));
      return 'DNS $host: ${addresses.map((a) => a.address).join(', ')}';
    } catch (e) {
      return 'DNS failed: $e';
    }
  }

  Future<String> _httpHeaders(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return 'Only HTTPS URLs are allowed.';
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      final buffer = StringBuffer();
      response.headers.forEach((name, values) => buffer.writeln('$name: ${values.join(', ')}'));
      return 'HTTPS headers for $uri:\n$buffer';
    } catch (e) {
      return 'HTTPS request failed: $e';
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _sslCheck(String host) async {
    if (!_isSafeHost(host)) return 'Invalid host.';
    try {
      final socket = await SecureSocket.connect(host, 443, timeout: const Duration(seconds: 5));
      final certificate = socket.peerCertificate;
      socket.destroy();
      return certificate == null ? 'No peer certificate returned.' : 'TLS certificate subject: ${certificate.subject}\nValid until: ${certificate.endValidity}';
    } catch (e) {
      return 'TLS check failed: $e';
    }
  }

  bool _isSafeHost(String value) => value.isNotEmpty && !value.contains(RegExp(r'[\s;/\\]'));

  String _systemInfo() => 'OS: ${Platform.operatingSystem}\nCPU: ${Platform.numberOfProcessors} cores\nDart: ${Platform.version}\nDebug: $kDebugMode';

  String _helpText() => '''
=== ZION OS — DEFENSIVE DIAGNOSTICS ===
system_info    - معلومات النظام
ping           - اختبار اتصال أساسي
DNS lookup     - تحليل DNS
https headers  - قراءة ترويسات HTTPS
ssl_check      - فحص شهادة TLS
network_info   - معلومات الشبكة
port_scan      - معطل في نسخة الإنتاج

الهجمات، كسر كلمات المرور، الاستغلال، Metasploit، Hydra، SQLMap،
Aircrack وعمليات الانتشار الذاتي ليست جزءاً من سطح الإنتاج.
''';
}
