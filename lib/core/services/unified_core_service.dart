import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:riverpod/riverpod.dart';
import 'live_network_monitor.dart';
import 'connection_info_service.dart';
import 'kali_loader_service.dart';

final unifiedCoreProvider = Provider<UnifiedCoreService>((ref) => UnifiedCoreService());

class UnifiedCoreService {
  final LiveNetworkMonitor _monitor = LiveNetworkMonitor();
  final ConnectionInfoService _connectionInfo = ConnectionInfoService();

  Future<String> execute(String command, {String? target, Map<String, String>? options}) async {
    try {
      // ============ أوامر تثبيت وتشغيل كالي ============
      switch (command) {
        case 'kali_install':
          return await KaliLoaderService.install();
        case 'kali_status':
          final status = await KaliLoaderService.getStatus();
          return const JsonEncoder.withIndent('  ').convert(status);
        case 'kali_tools':
          final count = await KaliLoaderService.getToolCount();
          return 'عدد الأدوات المتاحة: $count+ أداة';
      }

      // ============ أوامر أدوات كالي الحقيقية ============
      if (command.startsWith('nmap')) {
        return await KaliLoaderService.nmap(target ?? '127.0.0.1', args: command.substring(4).trim());
      }
      switch (command) {
        case 'msfconsole': return await KaliLoaderService.msfconsole(options?['commands'] ?? 'version');
        case 'sqlmap': return await KaliLoaderService.sqlmap(target ?? 'http://localhost');
        case 'hydra': return await KaliLoaderService.hydra(target ?? '127.0.0.1', options?['service'] ?? 'ssh', options?['user'] ?? 'root', options?['wordlist'] ?? '/usr/share/wordlists/rockyou.txt');
        case 'aircrack': return await KaliLoaderService.aircrack(options?['cap'] ?? '/tmp/capture.cap', options?['wordlist'] ?? '/usr/share/wordlists/rockyou.txt');
        case 'john': return await KaliLoaderService.john(options?['hash'] ?? '');
        case 'nikto': return await KaliLoaderService.nikto(target ?? 'http://localhost');
        case 'dirb': return await KaliLoaderService.dirb(target ?? 'http://localhost');
        case 'wpscan': return await KaliLoaderService.wpscan(target ?? 'http://localhost');
        case 'kali_shell':
          final result = await KaliLoaderService.execute(options?['cmd'] ?? 'uname -a');
          return result['stdout'] ?? result['stderr'] ?? 'No output';
      }

      // ============ مراقبة الشبكة ============
      switch (command) {
        case 'net_start': await _monitor.start(); return 'Network monitoring started.';
        case 'net_stop': _monitor.stop(); return 'Network monitoring stopped.';
        case 'net_connections':
          return _monitor.getActiveConnections().take(10).map((c) => '${c['protocol']} ${c['local_address']} -> ${c['foreign_address']} [${c['state']}]').join('\n');
        case 'net_stats':
          return _monitor.getConnectionStats().entries.map((e) => '${e.key}: ${e.value}').join('\n');
        case 'net_top':
          return _monitor.getTopConnections().take(5).map((t) => '${t['address']}: ${t['count']}').join('\n');
      }

      // ============ معلومات الاتصال ============
      switch (command) {
        case 'ip_local': return 'Local IP: ${await _connectionInfo.getLocalIP()}';
        case 'ip_public': return 'Public IP: ${await _connectionInfo.getPublicIP()}';
        case 'network_info': return (await _connectionInfo.getNetworkInfo()).toString();
        case 'ping_test': final p = await _connectionInfo.pingTest(); return 'Ping ${p['host']}: ${p['avg_time_ms']}ms avg';
      }

      // ============ أوامر الشبكة الأساسية ============
      switch (command) {
        case 'ping': return await _ping(target ?? '127.0.0.1');
        case 'port_scan': return await _portScan(target ?? '127.0.0.1');
        case 'dns_lookup': return await _dnsLookup(target ?? 'google.com');
        case 'http_headers': return await _httpHeaders(target ?? 'http://google.com');
        case 'ssl_check': return await _sslCheck(target ?? 'google.com');
        case 'system_info': return _systemInfo();
      }

      if (command == 'help') return _helpText();
      return 'Unknown: $command. Type help.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> _ping(String t) async {
    try { return (await Process.run('ping', ['-c', '4', t], runInShell: true)).stdout.toString(); } catch (e) { return 'Ping failed: $e'; }
  }
  Future<String> _portScan(String t) async {
    final p = [21, 22, 23, 25, 53, 80, 443, 8080, 8443]; final o = <String>[];
    for (final x in p) { try { final s = await Socket.connect(t, x, timeout: const Duration(milliseconds: 500)); o.add('$x'); s.destroy(); } catch (_) {} }
    return 'Port scan $t: ${o.isNotEmpty ? o.join(', ') : "none"}';
  }
  Future<String> _dnsLookup(String d) async {
    try { final a = await InternetAddress.lookup(d); return 'DNS $d: ${a.map((x) => x.address).join(', ')}'; } catch (e) { return 'DNS failed: $e'; } }
  }
  Future<String> _httpHeaders(String url) async {
    try {
      final c = HttpClient(); final r = await c.getUrl(Uri.parse(url)); final res = await r.close();
      final buf = StringBuffer(); res.headers.forEach((k, v) => buf.writeln('$k: ${v.join(', ')}'));
      return 'HTTP Headers for $url:\n$buf';
    } catch (e) { return 'HTTP failed: $e'; }
  }
  Future<String> _sslCheck(String host) async {
    try {
      final s = await SecureSocket.connect(host, 443, timeout: const Duration(seconds: 5));
      final cert = s.peerCertificate; s.destroy();
      return cert != null ? 'SSL Valid: ${cert.subject}\nUntil: ${cert.endValidity}' : 'No certificate';
    } catch (e) { return 'SSL failed: $e'; }
  }
  String _systemInfo() => 'OS: ${Platform.operatingSystem}\nCPU: ${Platform.numberOfProcessors} cores\nDart: ${Platform.version}';

  String _helpText() => '''
=== PROJECT ZION - KALI LINUX INTEGRATION ===
📦 Kali Setup:
  kali_install      - تثبيت Kali Linux تلقائيًا
  kali_status       - عرض حالة Kali
  kali_tools        - عدد الأدوات المتاحة

🔧 Kali Tools (600+):
  nmap <target>     - فحص الشبكات
  msfconsole        - Metasploit Framework
  sqlmap <url>      - فحص SQL Injection
  hydra <target>    - كسر كلمات المرور
  aircrack          - كسر شبكات WiFi
  john              - كسر التجزئات
  nikto <url>       - فحص خوادم الويب
  dirb <url>        - اكتشاف المجلدات
  wpscan <url>      - فحص WordPress
  kali_shell <cmd>  - تنفيذ أمر مخصص

📡 Network:
  net_start/stop, net_connections, net_stats, net_top
  ping, port_scan, dns_lookup, http_headers, ssl_check
=================================================
''';
}

  case 'proot_status':
    final prootPath = await KaliLoaderService.findProot();
    if (prootPath != null) {
      return '✅ proot موجود: $prootPath';
    } else {
      return '❌ proot غير موجود. سيتم استخراج المدمج تلقائيًا.';
    }
