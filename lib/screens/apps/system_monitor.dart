import 'dart:async';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Reads metrics from Linux/Android procfs and sysfs. Unsupported metrics stay
/// unavailable instead of being replaced with fabricated values.
class SystemMonitorApp extends StatefulWidget {
  const SystemMonitorApp({super.key});

  @override
  State<SystemMonitorApp> createState() => _SystemMonitorAppState();
}

class _SystemMonitorAppState extends State<SystemMonitorApp> {
  static const Color _accent = Color(0xFF38BDF8);
  static const Color _surface = Color(0xFF111C2B);

  Timer? _timer;
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;
  double? _cpuUsage;
  double? _ramUsage;
  double? _diskUsage;
  double? _temperature;
  int? _totalRamMb;
  int? _usedRamMb;
  int? _freeRamMb;
  int? _totalDiskMb;
  int? _usedDiskMb;
  int? _freeDiskMb;
  int? _processCount;
  int? _uptimeSeconds;
  final List<FlSpot> _cpuHistory = <FlSpot>[];
  final List<FlSpot> _ramHistory = <FlSpot>[];
  int _sample = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<double?> _readCpuUsage() async {
    Future<List<int>?> readCounters() async {
      try {
        final line = (await File('/proc/stat').readAsLines())
            .firstWhere((value) => value.startsWith('cpu '));
        final values = line.trim().split(RegExp(r'\s+')).skip(1)
            .map(int.tryParse).whereType<int>().toList();
        if (values.length < 4) return null;
        final idle = values[3] + (values.length > 4 ? values[4] : 0);
        return <int>[values.fold<int>(0, (sum, value) => sum + value), idle];
      } catch (_) {
        return null;
      }
    }

    final first = await readCounters();
    if (first == null) return null;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final second = await readCounters();
    if (second == null) return null;
    final total = second[0] - first[0];
    final idle = second[1] - first[1];
    if (total <= 0) return null;
    return ((total - idle) * 100 / total).clamp(0, 100).toDouble();
  }

  Future<Map<String, int>?> _readMemory() async {
    try {
      final lines = await File('/proc/meminfo').readAsLines();
      final values = <String, int>{};
      for (final line in lines) {
        final match = RegExp(r'^(MemTotal|MemAvailable):\s+(\d+)\s+kB')
            .firstMatch(line);
        if (match != null) values[match.group(1)!] = int.parse(match.group(2)!);
      }
      final total = values['MemTotal'];
      final available = values['MemAvailable'];
      if (total == null || available == null || total <= 0) return null;
      final used = (total - available).clamp(0, total);
      return <String, int>{
        'total': total ~/ 1024,
        'used': used ~/ 1024,
        'free': available ~/ 1024,
        'percent': (used * 100 ~/ total),
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, int>?> _readDisk() async {
    try {
      final result = await Process.run('df', <String>['-k', '/data']);
      if (result.exitCode != 0) return null;
      final lines = result.stdout.toString().trim().split('\n');
      if (lines.length < 2) return null;
      final parts = lines.last.trim().split(RegExp(r'\s+'));
      if (parts.length < 6) return null;
      final total = int.tryParse(parts[1]);
      final used = int.tryParse(parts[2]);
      final free = int.tryParse(parts[3]);
      if (total == null || used == null || free == null || total <= 0) {
        return null;
      }
      return <String, int>{
        'total': total ~/ 1024,
        'used': used ~/ 1024,
        'free': free ~/ 1024,
        'percent': (used * 100 ~/ total).clamp(0, 100),
      };
    } catch (_) {
      return null;
    }
  }

  Future<double?> _readTemperature() async {
    try {
      final zones = Directory('/sys/class/thermal');
      await for (final entity in zones.list(followLinks: false)) {
        if (entity is! Directory ||
            !RegExp(r'thermal_zone\d+').hasMatch(entity.path.split('/').last)) {
          continue;
        }
        try {
          final raw = (await File('${entity.path}/temp').readAsString()).trim();
          final value = double.tryParse(raw);
          if (value == null || value <= 0) continue;
          return value > 1000 ? value / 1000 : value;
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      // Thermal sysfs is restricted on some Android devices.
    }
    return null;
  }

  Future<int?> _readProcessCount() async {
    try {
      var count = 0;
      await for (final entity in Directory('/proc').list(followLinks: false)) {
        if (RegExp(r'^\d+$').hasMatch(entity.path.split('/').last)) count++;
      }
      return count;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _readUptime() async {
    try {
      final raw = (await File('/proc/uptime').readAsString()).trim();
      return double.parse(raw.split(RegExp(r'\s+')).first).floor();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    if (_loading == false) {
      setState(() => _error = null);
    }
    try {
      final results = await Future.wait<Object?>(<Future<Object?>>[
        _readCpuUsage(),
        _readMemory(),
        _readDisk(),
        _readTemperature(),
        _readProcessCount(),
        _readUptime(),
      ]);
      if (!mounted) return;
      final memory = results[1] as Map<String, int>?;
      final disk = results[2] as Map<String, int>?;
      setState(() {
        _cpuUsage = results[0] as double?;
        _ramUsage = memory?['percent']?.toDouble();
        _totalRamMb = memory?['total'];
        _usedRamMb = memory?['used'];
        _freeRamMb = memory?['free'];
        _diskUsage = disk?['percent']?.toDouble();
        _totalDiskMb = disk?['total'];
        _usedDiskMb = disk?['used'];
        _freeDiskMb = disk?['free'];
        _temperature = results[3] as double?;
        _processCount = results[4] as int?;
        _uptimeSeconds = results[5] as int?;
        _lastUpdated = DateTime.now();
        _loading = false;
        _error = null;
        _sample++;
        _appendPoint(_cpuHistory, _cpuUsage);
        _appendPoint(_ramHistory, _ramUsage);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر تحديث بيانات النظام: $error';
      });
    }
  }

  void _appendPoint(List<FlSpot> points, double? value) {
    if (value == null) return;
    points.add(FlSpot(_sample.toDouble(), value));
    if (points.length > 24) points.removeAt(0);
  }

  String _formatBytes(int? mb) {
    if (mb == null) return 'غير متاح';
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '$mb MB';
  }

  String _formatUptime(int? seconds) {
    if (seconds == null) return 'غير متاح';
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '$days يوم، $hours ساعة';
    if (hours > 0) return '$hours ساعة، $minutes دقيقة';
    return '$minutes دقيقة';
  }

  Color _statusColor(double? value) {
    if (value == null) return Colors.white38;
    if (value < 60) return const Color(0xFF34D399);
    if (value < 85) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('مراقبة النظام'),
        backgroundColor: const Color(0xFF0B1220),
        actions: <Widget>[
          IconButton(
            tooltip: 'تحديث الآن',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: _accent),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _accent,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: 16),
            if (_error != null) _buildError(),
            if (_loading && _lastUpdated == null)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator(color: _accent)),
              )
            else ...<Widget>[
              _buildMetricCard(
                title: 'المعالج CPU',
                value: _cpuUsage,
                icon: Icons.memory_rounded,
                history: _cpuHistory,
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: 'الذاكرة RAM',
                value: _ramUsage,
                icon: Icons.storage_rounded,
                history: _ramHistory,
                details: 'المستخدم ${_formatBytes(_usedRamMb)}  •  المتاح ${_formatBytes(_freeRamMb)}  •  الإجمالي ${_formatBytes(_totalRamMb)}',
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: 'التخزين الداخلي',
                value: _diskUsage,
                icon: Icons.sd_storage_rounded,
                details: 'المستخدم ${_formatBytes(_usedDiskMb)}  •  المتاح ${_formatBytes(_freeDiskMb)}  •  الإجمالي ${_formatBytes(_totalDiskMb)}',
              ),
              const SizedBox(height: 12),
              _buildSystemDetails(),
            ],
            const SizedBox(height: 12),
            Text(
              'تُعرض فقط القياسات التي أمكن قراءتها من النظام. قد لا تسمح بعض إصدارات Android بقراءة حرارة الجهاز أو بعض إحصاءات الموارد.',
              style: TextStyle(color: Colors.white.withOpacity(0.48), fontSize: 11, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final time = _lastUpdated;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _accent.withOpacity(0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.monitor_heart_rounded, color: _accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('حالة الجهاز', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  time == null ? 'جارٍ جمع القياسات...' : 'آخر تحديث ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
        ],
      ),
    );
  }

  Widget _buildError() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF3B1D28), borderRadius: BorderRadius.circular(14)),
    child: Row(children: <Widget>[
      const Icon(Icons.error_outline, color: Color(0xFFFCA5A5)),
      const SizedBox(width: 10),
      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      TextButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
    ]),
  );

  Widget _buildMetricCard({
    required String title,
    required double? value,
    required IconData icon,
    List<FlSpot>? history,
    String? details,
  }) {
    final color = _statusColor(value);
    final shown = value == null ? '—' : '${value.toStringAsFixed(1)}%';
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Icon(icon, color: _accent, size: 20),
            const SizedBox(width: 9),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            Text(shown, style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: value == null ? 0 : value.clamp(0, 100) / 100,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (history != null && history.length > 1) ...<Widget>[
            const SizedBox(height: 14),
            SizedBox(
              height: 62,
              child: LineChart(LineChartData(
                minY: 0,
                maxY: 100,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: history,
                    isCurved: true,
                    color: _accent,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: _accent.withOpacity(0.08)),
                  ),
                ],
              )),
            ),
          ],
          if (details != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(details, style: const TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.start),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemDetails() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Text('معلومات النظام', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      _detailRow(Icons.device_thermostat_rounded, 'درجة الحرارة', _temperature == null ? 'غير متاحة' : '${_temperature!.toStringAsFixed(1)} °C'),
      _detailRow(Icons.memory_rounded, 'العمليات المرئية', _processCount?.toString() ?? 'غير متاح'),
      _detailRow(Icons.timer_outlined, 'مدة تشغيل الجهاز', _formatUptime(_uptimeSeconds)),
    ]),
  );

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: <Widget>[
      Icon(icon, color: _accent, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}
