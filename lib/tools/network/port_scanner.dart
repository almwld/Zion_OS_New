import 'dart:async';
import 'dart:io';
import 'dart:math';

class PortScanner {
  // قاعدة بيانات الثغرات المدمجة
  static const Map<int, String> _vulnerabilityDB = {
    21: 'FTP - Check for anonymous login',
    22: 'SSH - Check for weak passwords',
    23: 'Telnet - Insecure protocol',
    25: 'SMTP - Check for open relay',
    53: 'DNS - Check for zone transfer',
    80: 'HTTP - Check for SQLi, XSS',
    110: 'POP3 - Check for weak passwords',
    135: 'RPC - Check for MS vulnerabilities',
    139: 'NetBIOS - Check for shares',
    143: 'IMAP - Check for weak passwords',
    443: 'HTTPS - Check for Heartbleed',
    445: 'SMB - Check for EternalBlue',
    1433: 'MSSQL - Check for weak passwords',
    3306: 'MySQL - Check for weak passwords',
    3389: 'RDP - Check for BlueKeep',
    5432: 'PostgreSQL - Check for weak passwords',
    6379: 'Redis - Check for unauthorized access',
    8080: 'HTTP-Alt - Check for admin panels',
    8443: 'HTTPS-Alt - Check for vulnerabilities',
    27017: 'MongoDB - Check for unauthorized access',
  };

  // بصمات أنظمة التشغيل (TTL-based)
  static String _fingerprintOS(int ttl) {
    if (ttl <= 64) return 'Linux/Unix';
    if (ttl <= 128) return 'Windows';
    if (ttl <= 255) return 'Cisco/Network Device';
    return 'Unknown';
  }

  /// المسح الشامل للمنافذ
  static Future<Map<String, dynamic>> fullScan(String target, {int timeout = 500}) async {
    final results = <String, dynamic>{
      'target': target,
      'timestamp': DateTime.now().toIso8601String(),
      'open_ports': <int>[],
      'vulnerabilities': <String>[],
      'os_fingerprint': 'Unknown',
      'services': <String, String>{},
    };

    // المرحلة 1: مسح المنافذ الشائعة
    final commonPorts = [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 1433, 3306, 3389, 5432, 6379, 8080, 8443, 27017];
    
    for (final port in commonPorts) {
      final isOpen = await _checkPort(target, port, timeout: timeout);
      if (isOpen) {
        (results['open_ports'] as List<int>).add(port);
      }
    }

    // المرحلة 2: بصمة نظام التشغيل
    results['os_fingerprint'] = await _detectOS(target);

    // المرحلة 3: فحص الثغرات
    for (final port in results['open_ports']) {
      if (_vulnerabilityDB.containsKey(port)) {
        (results['vulnerabilities'] as List<String>).add('Port $port: ${_vulnerabilityDB[port]}');
      }
    }

    // المرحلة 4: تحديد الخدمات
    for (final port in results['open_ports']) {
      final service = await _detectService(target, port);
      if (service != null) {
        (results['services'] as Map<String, String>)[port.toString()] = service;
      }
    }

    return results;
  }

  /// المسح السريع (أهم 100 منفذ)
  static Future<List<int>> quickScan(String target, {int timeout = 300}) async {
    final openPorts = <int>[];
    final top100 = [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 1433, 3306, 3389, 5432, 6379, 8080, 8443, 27017];
    
    await Future.wait(top100.map((port) async {
      if (await _checkPort(target, port, timeout: timeout)) {
        openPorts.add(port);
      }
    }));
    
    openPorts.sort();
    return openPorts;
  }

  /// المسح الكامل (1-1000)
  static Future<List<int>> deepScan(String target, {int timeout = 200}) async {
    final openPorts = <int>[];
    final batchSize = 50;
    
    for (int i = 1; i <= 1000; i += batchSize) {
      final batch = List.generate(
        i + batchSize > 1000 ? 1000 - i + 1 : batchSize,
        (index) => i + index,
      );
      
      await Future.wait(batch.map((port) async {
        if (await _checkPort(target, port, timeout: timeout)) {
          openPorts.add(port);
        }
      }));
    }
    
    return openPorts;
  }

  /// المسح العنقودي (متعدد الأهداف)
  static Future<Map<String, List<int>>> clusterScan(List<String> targets, {int timeout = 500}) async {
    final results = <String, List<int>>{};
    
    await Future.wait(targets.map((target) async {
      results[target] = await quickScan(target, timeout: timeout);
    }));
    
    return results;
  }

  /// فحص منفذ واحد
  static Future<bool> _checkPort(String target, int port, {int timeout = 500}) async {
    try {
      final socket = await Socket.connect(
        target,
        port,
        timeout: Duration(milliseconds: timeout),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// اكتشاف نظام التشغيل
  static Future<String> _detectOS(String target) async {
    try {
      final result = await Process.run('ping', ['-c', '1', target]);
      final output = result.stdout.toString();
      
      // استخراج TTL من مخرجات ping
      final ttlMatch = RegExp(r'ttl=(\d+)', caseSensitive: false).firstMatch(output);
      if (ttlMatch != null) {
        final ttl = int.parse(ttlMatch.group(1)!);
        return _fingerprintOS(ttl);
      }
    } catch (_) {}
    
    return 'Unknown';
  }

  /// اكتشاف الخدمة
  static Future<String?> _detectService(String target, int port) async {
    try {
      final socket = await Socket.connect(target, port, timeout: const Duration(milliseconds: 500));
      
      // انتظر قليلاً لاستقبال البانر
      await Future.delayed(const Duration(milliseconds: 200));
      
      String? banner;
      try {
        socket.listen((data) {
          banner = String.fromCharCodes(data).trim();
        });
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (_) {}
      
      socket.destroy();
      return banner;
    } catch (_) {
      return null;
    }
  }

  /// توليد تقرير
  static String generateReport(Map<String, dynamic> scanResult) {
    final report = StringBuffer();
    report.writeln('=' * 60);
    report.writeln('PORT SCAN REPORT');
    report.writeln('=' * 60);
    report.writeln('Target: ${scanResult['target']}');
    report.writeln('Time: ${scanResult['timestamp']}');
    report.writeln('OS Fingerprint: ${scanResult['os_fingerprint']}');
    report.writeln('');
    report.writeln('Open Ports (${(scanResult['open_ports'] as List).length}):');
    for (final port in scanResult['open_ports']) {
      final service = scanResult['services']?[port.toString()] ?? '';
      report.writeln('  $port ${service.isNotEmpty ? "- $service" : ""}');
    }
    report.writeln('');
    report.writeln('Potential Vulnerabilities:');
    for (final vuln in scanResult['vulnerabilities'] ?? []) {
      report.writeln('  [!] $vuln');
    }
    report.writeln('=' * 60);
    return report.toString();
  }
}
