import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

class LegendaryScanner {
  static const String _reset = '\x1b[0m';
  static const String _red = '\x1b[31m';
  static const String _green = '\x1b[32m';
  static const String _yellow = '\x1b[33m';
  static const String _blue = '\x1b[34m';
  static const String _cyan = '\x1b[36m';

  /// المسح الأسطوري الشامل (Nmap-style)
  static Future<Map<String, dynamic>> legendaryScan(
    String target, {
    bool aggressive = true,
    bool detectOS = true,
    bool detectServices = true,
    bool detectVulns = true,
    int speed = 4, // 1-5
  }) async {
    final results = <String, dynamic>{
      'target': target,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'scanning',
      'open_ports': <Map<String, dynamic>>[],
      'os_matches': <Map<String, dynamic>>[],
      'vulnerabilities': <Map<String, dynamic>>{},
      'trace_route': <Map<String, dynamic>>{},
    };

    // المرحلة 1: اكتشاف إذا كان الهدف حيًا
    final isAlive = await _pingSweep(target);
    if (!isAlive && !aggressive) {
      results['status'] = 'Host seems down. Use aggressive mode to scan anyway.';
      return results;
    }
    results['status'] = 'up';

    // المرحلة 2: مسح المنافذ (حسب السرعة)
    final portRanges = _getPortRanges(speed);
    final scannedPorts = await _scanPortRange(target, portRanges['start']!, portRanges['end']!, aggressive: aggressive);
    results['open_ports'] = scannedPorts;

    // المرحلة 3: اكتشاف الخدمات
    if (detectServices) {
      for (final portInfo in scannedPorts) {
        final service = await _detectService(target, portInfo['port']! as int);
        portInfo['service'] = service['name'];
        portInfo['product'] = service['product'];
        portInfo['version'] = service['version'];
        portInfo['banner'] = service['banner'];
      }
    }

    // المرحلة 4: اكتشاف نظام التشغيل
    if (detectOS) {
      results['os_matches'] = await _detectOS(target);
    }

    // المرحلة 5: فحص الثغرات
    if (detectVulns) {
      results['vulnerabilities'] = _scanVulnerabilities(scannedPorts);
    }

    // المرحلة 6: تتبع المسار
    if (aggressive) {
      results['trace_route'] = await _traceRoute(target);
    }

    return results;
  }

  /// Ping Sweep
  static Future<bool> _pingSweep(String target) async {
    try {
      final result = await Process.run('ping', ['-c', '1', '-W', '1', target], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      // محاولة TCP SYN على المنفذ 80
      try {
        final socket = await Socket.connect(target, 80, timeout: const Duration(seconds: 1));
        socket.destroy();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// تحديد نطاق المنافذ حسب السرعة
  static Map<String, int> _getPortRanges(int speed) {
    switch (speed) {
      case 1: return {'start': 1, 'end': 100};
      case 2: return {'start': 1, 'end': 1024};
      case 3: return {'start': 1, 'end': 10000};
      case 4: return {'start': 1, 'end': 30000};
      case 5: return {'start': 1, 'end': 65535};
      default: return {'start': 1, 'end': 1024};
    }
  }

  /// مسح نطاق من المنافذ
  static Future<List<Map<String, dynamic>>> _scanPortRange(
    String target, int start, int end, {bool aggressive = false}) async {
    final openPorts = <Map<String, dynamic>>[];
    final batchSize = aggressive ? 100 : 30;
    int scanned = 0;
    int total = end - start + 1;

    for (int i = start; i <= end; i += batchSize) {
      final batch = List.generate(
        i + batchSize > end ? end - i + 1 : batchSize,
        (index) => i + index,
      );

      await Future.wait(batch.map((port) async {
        try {
          // TCP SYN (محاكاة)
          final socket = await Socket.connect(target, port, timeout: const Duration(milliseconds: 300));
          final state = 'open';

          // محاولة UDP لبعض المنافذ
          if (port == 53 || port == 161 || port == 123) {
            try {
              final udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
              udpSocket.send([0], InternetAddress(target), port);
              udpSocket.close();
            } catch (_) {}
          }

          openPorts.add({
            'port': port,
            'state': state,
            'protocol': port == 53 ? 'udp' : 'tcp',
          });

          socket.destroy();
        } catch (_) {
          // المنفذ مغلق أو مُصفى
        }
        scanned++;
      }));
    }

    openPorts.sort((a, b) => (a['port'] as int).compareTo(b['port'] as int));
    return openPorts;
  }

  /// اكتشاف الخدمة
  static Future<Map<String, dynamic>> _detectService(String target, int port) async {
    final result = {'name': 'unknown', 'product': '', 'version': '', 'banner': ''};

    // قاعدة بيانات الخدمات
    final knownServices = {
      21: 'ftp', 22: 'ssh', 23: 'telnet', 25: 'smtp', 53: 'dns',
      80: 'http', 110: 'pop3', 143: 'imap', 443: 'https', 445: 'smb',
      3306: 'mysql', 3389: 'rdp', 5432: 'postgresql', 6379: 'redis',
      8080: 'http-proxy', 8443: 'https-alt', 27017: 'mongodb',
    };

    result['name'] = knownServices[port] ?? 'unknown';

    // محاولة جلب البانر
    try {
      final socket = await Socket.connect(target, port, timeout: const Duration(seconds: 2));
      
      // إرسال طلب مخصص حسب الخدمة
      final probe = _getProbe(port);
      if (probe != null) {
        socket.write(probe);
        await socket.flush();
      }

      // قراءة الرد
      final buffer = <int>[];
      socket.listen((data) {
        buffer.addAll(data);
      });

      await Future.delayed(const Duration(milliseconds: 500));
      socket.destroy();

      if (buffer.isNotEmpty) {
        result['banner'] = String.fromCharCodes(buffer).trim();
        result['product'] = _parseProduct(result['banner']!);
        result['version'] = _parseVersion(result['banner']!);
      }
    } catch (_) {}

    return result;
  }

  /// الحصول على مسبار مناسب للمنفذ
  static String? _getProbe(int port) {
    switch (port) {
      case 80: case 8080: return 'GET / HTTP/1.0\r\n\r\n';
      case 443: case 8443: return 'HEAD / HTTP/1.0\r\n\r\n';
      case 25: return 'EHLO test\r\n';
      case 110: return 'USER test\r\n';
      case 143: return 'A1 CAPABILITY\r\n';
      default: return null;
    }
  }

  /// استخراج اسم المنتج من البانر
  static String _parseProduct(String banner) {
    if (banner.contains('Apache')) return 'Apache HTTP Server';
    if (banner.contains('nginx')) return 'Nginx';
    if (banner.contains('OpenSSH')) return 'OpenSSH';
    if (banner.contains('MySQL')) return 'MySQL';
    if (banner.contains('PostgreSQL')) return 'PostgreSQL';
    if (banner.contains('Redis')) return 'Redis';
    return '';
  }

  /// استخراج الإصدار من البانر
  static String _parseVersion(String banner) {
    final versionMatch = RegExp(r'(\d+\.\d+(\.\d+)?)').firstMatch(banner);
    return versionMatch?.group(1) ?? '';
  }

  /// اكتشاف نظام التشغيل
  static Future<List<Map<String, dynamic>>> _detectOS(String target) async {
    final matches = <Map<String, dynamic>>[];

    try {
      // استخدام TTL من ping
      final pingResult = await Process.run('ping', ['-c', '1', target], runInShell: true);
      final ttlMatch = RegExp(r'ttl=(\d+)', caseSensitive: false).firstMatch(pingResult.stdout.toString());

      if (ttlMatch != null) {
        final ttl = int.parse(ttlMatch.group(1)!);
        matches.add({
          'method': 'TTL',
          'ttl': ttl,
          'os': _guessOSByTTL(ttl),
          'accuracy': '80%',
        });
      }
    } catch (_) {}

    // محاولة اكتشاف عبر منافذ محددة
    try {
      final socket = await Socket.connect(target, 445, timeout: const Duration(seconds: 2));
      matches.add({
        'method': 'SMB',
        'os': 'Windows (SMB port open)',
        'accuracy': '60%',
      });
      socket.destroy();
    } catch (_) {}

    return matches;
  }

  /// تخمين نظام التشغيل من TTL
  static String _guessOSByTTL(int ttl) {
    if (ttl <= 64) return 'Linux/Unix/Android';
    if (ttl <= 128) return 'Windows';
    if (ttl <= 255) return 'Cisco/Network Device';
    return 'Unknown';
  }

  /// فحص الثغرات المعروفة
  static Map<String, dynamic> _scanVulnerabilities(List<Map<String, dynamic>> openPorts) {
    final vulns = <String, dynamic>{};
    int criticalCount = 0;
    int highCount = 0;

    for (final portInfo in openPorts) {
      final port = portInfo['port'] as int;
      final service = portInfo['service'] as String? ?? 'unknown';
      final version = portInfo['version'] as String? ?? '';

      if (_vulnDB.containsKey(port)) {
        final portVulns = _vulnDB[port]!;
        final matchingVulns = <Map<String, String>>[];

        for (final vuln in portVulns) {
          if (version.isEmpty || vuln['version'] == null || version.contains(vuln['version']!)) {
            matchingVulns.add(vuln);
            if (vuln['severity'] == 'Critical') criticalCount++;
            if (vuln['severity'] == 'High') highCount++;
          }
        }

        if (matchingVulns.isNotEmpty) {
          vulns['$port'] = matchingVulns;
        }
      }
    }

    vulns['summary'] = {
      'critical': criticalCount,
      'high': highCount,
      'total': criticalCount + highCount,
    };

    return vulns;
  }

  /// تتبع المسار
  static Future<Map<String, dynamic>> _traceRoute(String target) async {
    final hops = <Map<String, dynamic>>[];

    try {
      final result = await Process.run('traceroute', ['-m', '15', target], runInShell: true);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines.skip(1)) {
          if (line.trim().isEmpty) continue;
          hops.add({'raw': line.trim()});
        }
      }
    } catch (_) {}

    return {'hops': hops, 'count': hops.length};
  }

  /// قاعدة بيانات الثغرات (مُصغرة)
  static final Map<int, List<Map<String, String>>> _vulnDB = {
    21: [
      {'name': 'vsftpd 2.3.4 Backdoor', 'cve': 'CVE-2011-2523', 'severity': 'Critical', 'version': '2.3.4'},
      {'name': 'Anonymous FTP Login', 'cve': '', 'severity': 'Medium'},
    ],
    22: [
      {'name': 'OpenSSH < 7.4 User Enumeration', 'cve': 'CVE-2018-15473', 'severity': 'Medium', 'version': '7.4'},
    ],
    445: [
      {'name': 'EternalBlue (MS17-010)', 'cve': 'CVE-2017-0144', 'severity': 'Critical'},
      {'name': 'SMBv1 Exploit', 'cve': 'CVE-2017-0143', 'severity': 'Critical'},
    ],
    3389: [
      {'name': 'BlueKeep', 'cve': 'CVE-2019-0708', 'severity': 'Critical'},
    ],
  };
}
