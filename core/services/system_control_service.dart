import 'dart:io';
import 'dart:async';

class SystemControlService {
  static final SystemControlService _instance = SystemControlService._internal();
  factory SystemControlService() => _instance;
  SystemControlService._internal();
  
  bool _isMonitoring = false;
  Timer? _monitorTimer;
  
  StreamController<Map<String, dynamic>> _systemStatsController = StreamController.broadcast();
  
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _collectSystemStats();
    });
  }
  
  void stopMonitoring() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
  }
  
  Future<void> _collectSystemStats() async {
    final stats = {
      'timestamp': DateTime.now().toIso8601String(),
      'cpu': await _getCPUUsage(),
      'ram': await _getRAMUsage(),
      'disk': await _getDiskUsage(),
      'temperature': await _getTemperature(),
      'uptime': await _getUptime(),
      'processes': await _getProcessCount(),
    };
    _systemStatsController.add(stats);
  }
  
  Future<double> _getCPUUsage() async {
    try {
      final result = await Process.run('top', ['-bn1'], runInShell: true);
      final output = result.stdout.toString();
      final match = RegExp(r'CPU:\s*(\d+)%').firstMatch(output);
      if (match != null) return double.parse(match.group(1)!);
    } catch (_) {}
    return 0;
  }
  
  Future<double> _getRAMUsage() async {
    try {
      final result = await Process.run('free', [], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final total = double.parse(parts[1]);
          final used = double.parse(parts[2]);
          return (used / total) * 100;
        }
      }
    } catch (_) {}
    return 0;
  }
  
  Future<double> _getDiskUsage() async {
    try {
      final result = await Process.run('df', ['/data'], runInShell: true);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          final used = double.parse(parts[2]);
          final total = double.parse(parts[3]);
          return (used / total) * 100;
        }
      }
    } catch (_) {}
    return 0;
  }
  
  Future<double> _getTemperature() async {
    try {
      final result = await Process.run('cat', ['/sys/class/thermal/thermal_zone0/temp'], runInShell: true);
      final temp = double.parse(result.stdout.toString().trim()) / 1000;
      return temp;
    } catch (_) {}
    return 35;
  }
  
  Future<int> _getUptime() async {
    try {
      final result = await Process.run('cat', ['/proc/uptime'], runInShell: true);
      final uptimeSeconds = double.parse(result.stdout.toString().split(' ')[0]);
      return uptimeSeconds.toInt();
    } catch (_) {}
    return 0;
  }
  
  Future<int> _getProcessCount() async {
    try {
      final result = await Process.run('ps', ['-e'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      return lines.length - 1;
    } catch (_) {}
    return 0;
  }
  
  Future<void> rebootSystem() async {
    try {
      await Process.run('su', ['-c', 'reboot'], runInShell: true);
    } catch (_) {
      await Process.run('reboot', [], runInShell: true);
    }
  }
  
  Future<void> shutdownSystem() async {
    try {
      await Process.run('su', ['-c', 'reboot -p'], runInShell: true);
    } catch (_) {
      await Process.run('reboot', ['-p'], runInShell: true);
    }
  }
  
  Future<void> restartUI() async {
    // إعادة تشغيل الواجهة
  }
  
  Stream<Map<String, dynamic>> get systemStats => _systemStatsController.stream;
  
  void dispose() {
    stopMonitoring();
    _systemStatsController.close();
  }
}
