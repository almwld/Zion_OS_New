import 'dart:async';
import 'dart:io';
import 'dart:convert';

class LiveNetworkMonitor {
  final List<Map<String, dynamic>> _connections = [];
  final List<Map<String, dynamic>> _dnsQueries = [];
  Timer? _monitorTimer;
  bool _isRunning = false;

  /// بدء المراقبة
  Future<void> start() async {
    _isRunning = true;
    _monitorTimer = Timer.periodic(const Duration(seconds: 3), (_) => _scanNetwork());
  }

  /// إيقاف المراقبة
  void stop() {
    _isRunning = false;
    _monitorTimer?.cancel();
  }

  /// فحص الشبكة
  Future<void> _scanNetwork() async {
    try {
      // الحصول على الاتصالات النشطة باستخدام netstat
      final netstatResult = await Process.run('netstat', ['-an'], runInShell: true);
      if (netstatResult.exitCode == 0) {
        _parseNetstatOutput(netstatResult.stdout.toString());
      }
    } catch (_) {}

    try {
      // الحصول على اتصالات TCP
      final ssResult = await Process.run('ss', ['-tunap'], runInShell: true);
      if (ssResult.exitCode == 0) {
        _parseSsOutput(ssResult.stdout.toString());
      }
    } catch (_) {}
  }

  /// تحليل مخرجات netstat
  void _parseNetstatOutput(String output) {
    final lines = output.split('\n');
    for (final line in lines) {
      if (line.contains('ESTABLISHED') || line.contains('LISTEN') || line.contains('TIME_WAIT')) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          final connection = {
            'protocol': parts[0],
            'local_address': parts.length > 3 ? parts[3] : '',
            'foreign_address': parts.length > 4 ? parts[4] : '',
            'state': parts.length > 5 ? parts[5] : 'UNKNOWN',
            'timestamp': DateTime.now().toIso8601String(),
          };
          _connections.add(connection);
          if (_connections.length > 500) _connections.removeAt(0);
        }
      }
    }
  }

  /// تحليل مخرجات ss
  void _parseSsOutput(String output) {
    final lines = output.split('\n');
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 5) {
        final connection = {
          'protocol': 'TCP',
          'local_address': parts[4],
          'foreign_address': parts.length > 5 ? parts[5] : '',
          'state': parts[1],
          'timestamp': DateTime.now().toIso8601String(),
        };
        _connections.add(connection);
        if (_connections.length > 500) _connections.removeAt(0);
      }
    }
  }

  /// الحصول على الاتصالات النشطة
  List<Map<String, dynamic>> getActiveConnections() {
    return _connections.reversed.toList();
  }

  /// الحصول على عدد الاتصالات
  Map<String, int> getConnectionStats() {
    final states = <String, int>{};
    for (final conn in _connections) {
      final state = conn['state'] ?? 'UNKNOWN';
      states[state] = (states[state] ?? 0) + 1;
    }
    return states;
  }

  /// الحصول على أكثر العناوين اتصالاً
  List<Map<String, dynamic>> getTopConnections() {
    final addressCount = <String, int>{};
    for (final conn in _connections) {
      final addr = conn['foreign_address'] ?? '';
      if (addr.isNotEmpty && addr != '*:*') {
        addressCount[addr] = (addressCount[addr] ?? 0) + 1;
      }
    }
    return addressCount.entries
        .map((e) => {'address': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }
}
