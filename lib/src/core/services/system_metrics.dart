import 'dart:io';

class SystemMetrics {
  const SystemMetrics({
    required this.cpuPercent,
    required this.memoryPercent,
    required this.memoryUsedBytes,
    required this.memoryTotalBytes,
    required this.storagePercent,
    required this.uptime,
  });

  final double cpuPercent;
  final double memoryPercent;
  final int memoryUsedBytes;
  final int memoryTotalBytes;
  final double storagePercent;
  final Duration uptime;

  static Future<SystemMetrics> read() async {
    final cpu = await _cpu();
    final memory = await _memory();
    final storage = await _storage();
    return SystemMetrics(
      cpuPercent: cpu,
      memoryPercent: memory.percent,
      memoryUsedBytes: memory.used,
      memoryTotalBytes: memory.total,
      storagePercent: storage,
      uptime: _uptime(),
    );
  }

  static Future<double> _cpu() async {
    try {
      final a = _cpuLine(await File('/proc/stat').readAsString());
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final b = _cpuLine(await File('/proc/stat').readAsString());
      if (a == null || b == null) return 0;
      final totalA = a.fold<int>(0, (s, v) => s + v);
      final totalB = b.fold<int>(0, (s, v) => s + v);
      final idleA = a.length > 4 ? a[3] + a[4] : a[3];
      final idleB = b.length > 4 ? b[3] + b[4] : b[3];
      final total = totalB - totalA;
      return total <= 0 ? 0 : ((total - (idleB - idleA)) / total * 100).clamp(0, 100).toDouble();
    } catch (_) { return 0; }
  }

  static List<int>? _cpuLine(String text) {
    for (final line in text.split('\n')) {
      if (!line.startsWith('cpu ')) continue;
      final p = line.trim().split(RegExp(r'\s+'));
      if (p.length < 5) return null;
      return p.skip(1).map(int.tryParse).whereType<int>().toList();
    }
    return null;
  }

  static Future<_Memory> _memory() async {
    try {
      final text = await File('/proc/meminfo').readAsString();
      final values = <String, int>{};
      for (final line in text.split('\n')) {
        final parts = line.split(':');
        if (parts.length != 2) continue;
        final v = int.tryParse(parts[1].trim().split(RegExp(r'\s+')).first);
        if (v != null) values[parts[0]] = v * 1024;
      }
      final total = values['MemTotal'] ?? 0;
      final available = values['MemAvailable'] ?? values['MemFree'] ?? 0;
      final used = (total - available).clamp(0, total);
      return _Memory(total, used, total == 0 ? 0 : used / total * 100);
    } catch (_) { return const _Memory(0, 0, 0); }
  }

  static Future<double> _storage() async {
    try {
      final r = await Process.run('df', ['-k', '/']);
      final lines = r.stdout.toString().trim().split('\n');
      if (lines.length < 2) return 0;
      final p = lines.last.trim().split(RegExp(r'\s+'));
      return p.length < 5 ? 0 : (double.tryParse(p[4].replaceAll('%', '')) ?? 0).clamp(0, 100).toDouble();
    } catch (_) { return 0; }
  }

  static Duration _uptime() {
    try {
      final s = double.tryParse(File('/proc/uptime').readAsStringSync().split(' ').first) ?? 0;
      return Duration(milliseconds: (s * 1000).round());
    } catch (_) { return Duration.zero; }
  }
}

class _Memory {
  const _Memory(this.total, this.used, this.percent);
  final int total;
  final int used;
  final double percent;
}
