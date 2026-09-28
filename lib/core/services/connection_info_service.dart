import 'dart:async';
import 'dart:io';
import 'dart:convert';

class ConnectionInfoService {
  /// الحصول على عنوان IP المحلي
  Future<String> getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  /// الحصول على عنوان IP العام
  Future<String> getPublicIP() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://api.ipify.org'));
      final response = await request.close();
      return await response.transform(utf8.decoder).join();
    } catch (_) {
      return 'Unknown';
    }
  }

  /// الحصول على معلومات الشبكة
  Future<Map<String, dynamic>> getNetworkInfo() async {
    final info = <String, dynamic>{
      'local_ip': await getLocalIP(),
      'public_ip': await getPublicIP(),
      'interfaces': <Map<String, dynamic>>[],
      'dns_servers': <String>[],
      'gateway': 'Unknown',
    };

    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        info['interfaces'].add({
          'name': interface.name,
          'addresses': interface.addresses.map((a) => a.address).toList(),
        });
      }
    } catch (_) {}

    // محاولة الحصول على DNS
    try {
      final resolvConf = File('/etc/resolv.conf');
      if (await resolvConf.exists()) {
        final lines = await resolvConf.readAsLines();
        for (final line in lines) {
          if (line.startsWith('nameserver')) {
            info['dns_servers'].add(line.split(' ').last);
          }
        }
      }
    } catch (_) {}

    return info;
  }

  /// فحص سرعة الاتصال (ping)
  Future<Map<String, dynamic>> pingTest({String host = '8.8.8.8', int count = 4}) async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await Process.run('ping', ['-c', count.toString(), host], runInShell: true);
      stopwatch.stop();

      final output = result.stdout.toString();
      final timeMatch = RegExp(r'time=(\d+\.?\d*)').allMatches(output);
      final times = timeMatch.map((m) => double.parse(m.group(1)!)).toList();

      return {
        'host': host,
        'success': result.exitCode == 0,
        'avg_time_ms': times.isEmpty ? 0 : times.reduce((a, b) => a + b) / times.length,
        'min_time_ms': times.isEmpty ? 0 : times.reduce((a, b) => a < b ? a : b),
        'max_time_ms': times.isEmpty ? 0 : times.reduce((a, b) => a > b ? a : b),
        'packet_loss': output.contains('0% packet loss') ? 0 : 100,
      };
    } catch (_) {
      return {'success': false, 'host': host};
    }
  }
}
