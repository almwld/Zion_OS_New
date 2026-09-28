import 'dart:async';
import 'dart:io';
import 'dart:convert';

class FingerprintAnalyzer {
  /// تحليل بصمة خادم كاملة
  static Future<Map<String, dynamic>> analyzeServer(String target, {int port = 80}) async {
    final results = <String, dynamic>{
      'target': target,
      'timestamp': DateTime.now().toIso8601String(),
      'services': <Map<String, dynamic>>[],
      'os_confidence': <String, double>{},
    };

    // HTTP Fingerprint
    if (port == 80 || port == 443 || port == 8080 || port == 8443) {
      final httpFingerprint = await _httpFingerprint(target, port);
      if (httpFingerprint.isNotEmpty) {
        results['services'].add(httpFingerprint);
        results['os_confidence'] = httpFingerprint['os_guess'];
      }
    }

    // SSL/TLS Fingerprint
    if (port == 443 || port == 8443) {
      final sslFingerprint = await _sslFingerprint(target, port);
      if (sslFingerprint.isNotEmpty) {
        results['services'].add(sslFingerprint);
      }
    }

    // TCP/IP Stack Fingerprint
    final tcpFingerprint = await _tcpFingerprint(target);
    if (tcpFingerprint.isNotEmpty) {
      results['services'].add(tcpFingerprint);
    }

    return results;
  }

  /// بصمة HTTP
  static Future<Map<String, dynamic>> _httpFingerprint(String target, int port) async {
    final result = <String, dynamic>{
      'service': 'HTTP',
      'port': port,
      'headers': <String, String>{},
      'technologies': <String>[],
      'os_guess': <String, double>{},
    };

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http${port == 443 ? 's' : ''}://$target:$port'));
      final response = await request.close();

      // جمع الرؤوس
      response.headers.forEach((name, values) {
        result['headers'][name] = values.join(', ');
      });

      final body = await response.transform(utf8.decoder).join();

      // اكتشاف التقنيات
      final server = response.headers.value('server') ?? '';
      final powered = response.headers.value('x-powered-by') ?? '';

      if (server.contains('Apache')) result['technologies'].add('Apache');
      if (server.contains('nginx')) result['technologies'].add('Nginx');
      if (server.contains('IIS')) result['technologies'].add('IIS');
      if (powered.contains('PHP')) result['technologies'].add('PHP');
      if (powered.contains('ASP.NET')) result['technologies'].add('ASP.NET');
      if (body.contains('wp-content')) result['technologies'].add('WordPress');
      if (body.contains('jquery')) result['technologies'].add('jQuery');
      if (body.contains('bootstrap')) result['technologies'].add('Bootstrap');

      // تخمين نظام التشغيل
      if (server.contains('Win') || server.contains('IIS')) {
        result['os_guess'] = {'Windows': 0.8, 'Linux': 0.2};
      } else if (server.contains('Apache') || server.contains('nginx')) {
        result['os_guess'] = {'Linux': 0.85, 'Unix': 0.15};
      }
    } catch (_) {}

    return result;
  }

  /// بصمة SSL/TLS
  static Future<Map<String, dynamic>> _sslFingerprint(String target, int port) async {
    final result = <String, dynamic>{'service': 'SSL/TLS', 'port': port};

    try {
      final socket = await SecureSocket.connect(target, port, timeout: const Duration(seconds: 5));
      final cert = socket.peerCertificate;
      if (cert != null) {
        result['subject'] = cert.subject;
        result['issuer'] = cert.issuer;
        result['valid_from'] = cert.startValidity.toIso8601String();
        result['valid_to'] = cert.endValidity.toIso8601String();
        result['is_expired'] = DateTime.now().isAfter(cert.endValidity);
        result['cipher'] = 'TLS_AES_256_GCM_SHA384'; // محاكاة
      }
      socket.destroy();
    } catch (_) {}

    return result;
  }

  /// بصمة TCP/IP Stack
  static Future<Map<String, dynamic>> _tcpFingerprint(String target) async {
    final result = <String, dynamic>{'service': 'TCP/IP Stack'};

    try {
      final socket = await Socket.connect(target, 80, timeout: const Duration(seconds: 3));
      result['ip'] = socket.remoteAddress.address;
      result['port'] = socket.remotePort;
      socket.destroy();

      // محاولة اكتشاف TTL
      final pingResult = await Process.run('ping', ['-c', '1', target], runInShell: true);
      final ttlMatch = RegExp(r'ttl=(\d+)', caseSensitive: false).firstMatch(pingResult.stdout.toString());
      if (ttlMatch != null) {
        final ttl = int.parse(ttlMatch.group(1)!);
        result['ttl'] = ttl;
        result['os_guess'] = ttl <= 64 ? 'Linux/Unix' : ttl <= 128 ? 'Windows' : 'Unknown';
      }
    } catch (_) {}

    return result;
  }

  /// تحليل بصمة متصفح
  static Map<String, dynamic> analyzeBrowser(String userAgent) {
    final result = <String, dynamic>{
      'user_agent': userAgent,
      'browser': 'Unknown',
      'os': 'Unknown',
      'device': 'Desktop',
    };

    if (userAgent.contains('Chrome')) result['browser'] = 'Chrome';
    else if (userAgent.contains('Firefox')) result['browser'] = 'Firefox';
    else if (userAgent.contains('Safari')) result['browser'] = 'Safari';

    if (userAgent.contains('Windows')) result['os'] = 'Windows';
    else if (userAgent.contains('Mac')) result['os'] = 'macOS';
    else if (userAgent.contains('Linux')) result['os'] = 'Linux';
    else if (userAgent.contains('Android')) { result['os'] = 'Android'; result['device'] = 'Mobile'; }
    else if (userAgent.contains('iPhone') || userAgent.contains('iPad')) { result['os'] = 'iOS'; result['device'] = 'Mobile'; }

    return result;
  }
}
