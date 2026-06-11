import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:io';

class FloatingRadarChart extends StatefulWidget {
  final VoidCallback onClose;
  
  const FloatingRadarChart({super.key, required this.onClose});

  @override
  State<FloatingRadarChart> createState() => _FloatingRadarChartState();
}

class _FloatingRadarChartState extends State<FloatingRadarChart> {
  // Position and size
  Offset _position = Offset.zero;
  double _width = 280;
  double _height = 280;
  bool _isDragging = false;
  bool _isResizing = false;
  
  // Data values (12 metrics)
  Map<String, double> _metrics = {
    'CPU': 0.0,
    'RAM': 0.0,
    'Storage': 0.0,
    'Battery': 0.0,
    'Network': 0.0,
    'Temp': 0.0,
    'Processes': 0.0,
    'Uptime': 0.0,
    'Disk I/O': 0.0,
    'GPU': 0.0,
    'Security': 0.0,
    'Performance': 0.0,
  };
  
  final List<String> _titles = [
    'CPU', 'RAM', 'Storage', 'Battery', 'Network', 'Temp',
    'Processes', 'Uptime', 'Disk I/O', 'GPU', 'Security', 'Performance'
  ];
  
  final List<Color> _colors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple,
    Colors.cyan, Colors.pink, Colors.amber, Colors.lime, Colors.teal,
    Colors.indigo, Colors.deepPurple
  ];
  
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _position = Offset(
      MediaQuery.of(context).size.width - _width - 20,
      MediaQuery.of(context).size.height - _height - 100,
    );
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _updateMetrics();
      setState(() {});
    });
  }

  void _updateMetrics() {
    setState(() {
      _metrics['CPU'] = _getCPUUsage();
      _metrics['RAM'] = _getRAMUsage();
      _metrics['Storage'] = _getStorageUsage();
      _metrics['Battery'] = _getBatteryLevel();
      _metrics['Network'] = _getNetworkLoad();
      _metrics['Temp'] = _getTemperature();
      _metrics['Processes'] = _getProcessCount() / 100; // normalize
      _metrics['Uptime'] = _getUptimeRatio();
      _metrics['Disk I/O'] = _getDiskIO();
      _metrics['GPU'] = _getGPULoad();
      _metrics['Security'] = _getSecurityScore();
      _metrics['Performance'] = _getPerformanceScore();
      
      // Clamp values between 0 and 1
      for (var key in _metrics.keys) {
        _metrics[key] = _metrics[key]!.clamp(0.0, 1.0);
      }
    });
  }

  // === حصول على بيانات حقيقية أو محاكاة ===
  double _getCPUUsage() {
    try {
      final result = Process.runSync('top', ['-bn1'], runInShell: true);
      final match = RegExp(r'CPU:\s*(\d+)%').firstMatch(result.stdout.toString());
      if (match != null) return double.parse(match.group(1)!) / 100;
    } catch (_) {}
    return 0.3 + (DateTime.now().millisecond % 50) / 100;
  }

  double _getRAMUsage() {
    try {
      final result = Process.runSync('free', [], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          return double.parse(parts[2]) / double.parse(parts[1]);
        }
      }
    } catch (_) {}
    return 0.45;
  }

  double _getStorageUsage() {
    try {
      final result = Process.runSync('df', ['/data'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          return double.parse(parts[2]) / double.parse(parts[1]);
        }
      }
    } catch (_) {}
    return 0.6;
  }

  double _getBatteryLevel() {
    try {
      final result = Process.runSync('dumpsys', ['battery'], runInShell: true);
      final match = RegExp(r'level: (\d+)').firstMatch(result.stdout.toString());
      if (match != null) return double.parse(match.group(1)!) / 100;
    } catch (_) {}
    return 0.75;
  }

  double _getNetworkLoad() {
    // محاكاة حركة الشبكة
    return 0.2 + (DateTime.now().second % 80) / 100;
  }

  double _getTemperature() {
    try {
      final result = Process.runSync('cat', ['/sys/class/thermal/thermal_zone0/temp'], runInShell: true);
      final temp = double.parse(result.stdout.toString().trim()) / 1000;
      return (temp / 80).clamp(0.0, 1.0);
    } catch (_) {}
    return 0.45;
  }

  double _getProcessCount() {
    try {
      final result = Process.runSync('ps', ['-e'], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      return (lines.length - 1).toDouble();
    } catch (_) {
      return 50;
    }
  }

  double _getUptimeRatio() {
    try {
      final result = Process.runSync('cat', ['/proc/uptime'], runInShell: true);
      final uptime = double.parse(result.stdout.toString().split(' ')[0]);
      // افتراض أقصى uptime 7 أيام = 604800 ثانية
      return (uptime / 604800).clamp(0.0, 1.0);
    } catch (_) {
      return 0.1;
    }
  }

  double _getDiskIO() {
    // محاكاة
    return 0.15 + (DateTime.now().millisecond % 30) / 100;
  }

  double _getGPULoad() {
    // محاكاة
    return 0.2 + (DateTime.now().second % 50) / 100;
  }

  double _getSecurityScore() {
    // محاكاة
    return 0.85;
  }

  double _getPerformanceScore() {
    // متوسط الأداء
    return 0.7;
  }

  List<RadarEntry> _getRadarEntries() {
    return _titles.map((title) => RadarEntry(value: _metrics[title] ?? 0.0)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BCD4).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // عنوان النافذة (للسحب)
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _position += details.delta;
                    // حدود الشاشة
                    _position = Offset(
                      _position.dx.clamp(0, MediaQuery.of(context).size.width - _width),
                      _position.dy.clamp(0, MediaQuery.of(context).size.height - _height - 50),
                    );
                  });
                },
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.radar, color: Color(0xFF00BCD4), size: 18),
                      const SizedBox(width: 8),
                      const Text('Radar Monitor', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
                      const Spacer(),
                      // زر تصغير (Collapse)
                      GestureDetector(
                        onTap: () => setState(() => _width = 48, _height = 48),
                        child: const Icon(Icons.minimize, color: Color(0xFF00BCD4), size: 18),
                      ),
                      const SizedBox(width: 8),
                      // زر إغلاق
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close, color: Color(0xFF00BCD4), size: 18),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              // منطقة الرسم البياني (قابلة للتكبير/التصغير)
              Expanded(
                child: GestureDetector(
                  onScaleUpdate: (details) {
                    setState(() {
                      double newWidth = (_width * details.scale).clamp(120.0, 500.0);
                      double newHeight = (_height * details.scale).clamp(120.0, 500.0);
                      _width = newWidth;
                      _height = newHeight;
                    });
                  },
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          fillColor: const Color(0xFF00BCD4).withOpacity(0.2),
                          borderColor: const Color(0xFF00BCD4),
                          borderWidth: 1.5,
                          entryRadius: 3,
                          dataEntries: _getRadarEntries(),
                        ),
                      ],
                      radarBorderData: const BorderSide(color: Color(0xFF00BCD4), width: 1),
                      titlePositionPercentageOffset: 1.1,
                      getTitle: (index, angle) {
                        return RadarChartTitle(
                          text: _titles[index],
                          angle: angle,
                          style: TextStyle(
                            color: _colors[index % _colors.length],
                            fontSize: _width < 200 ? 8 : 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      ticks: const [0.25, 0.5, 0.75, 1.0],
                      tickBorderData: const BorderSide(color: Color(0xFF00BCD4), width: 0.5),
                      tickTextStyle: const TextStyle(color: Colors.white38, fontSize: 8),
                    ),
                  ),
                ),
              ),
              // شريط الحالة السفلي (إظهار القيم)
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _titles.map((title) {
                      double val = _metrics[title] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '$title: ${(val * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: _colors[_titles.indexOf(title)], fontSize: 9),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
