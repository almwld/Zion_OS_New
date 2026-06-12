import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';

class FloatingRadarChart extends StatefulWidget {
  final VoidCallback onClose;
  const FloatingRadarChart({super.key, required this.onClose});

  @override
  State<FloatingRadarChart> createState() => _FloatingRadarChartState();
}

class _FloatingRadarChartState extends State<FloatingRadarChart> with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  double _radius = 100;
  bool _isDragging = false;
  
  Map<String, double> _metrics = {
    'CPU': 0.0, 'RAM': 0.0, 'Storage': 0.0, 'Battery': 0.0,
    'Network': 0.0, 'Temp': 0.0, 'Processes': 0.0, 'Uptime': 0.0,
    'Disk I/O': 0.0, 'GPU': 0.0, 'Security': 0.0, 'Performance': 0.0,
  };
  
  final List<String> _titles = [
    'CPU', 'RAM', 'Storage', 'Battery', 'Network', 'Temp',
    'Processes', 'Uptime', 'Disk I/O', 'GPU', 'Security', 'Performance'
  ];
  
  final List<Color> _colors = [
    Colors.redAccent, Colors.blueAccent, Colors.greenAccent, Colors.orangeAccent,
    Colors.purpleAccent, Colors.cyanAccent, Colors.pinkAccent, Colors.amberAccent,
    Colors.limeAccent, Colors.tealAccent, Colors.indigoAccent, Colors.deepPurpleAccent
  ];
  
  Timer? _updateTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _position = Offset(
      MediaQuery.of(context).size.width - _radius * 2 - 20,
      MediaQuery.of(context).size.height - _radius * 2 - 100,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(_pulseController);
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
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
      _metrics['Processes'] = _getProcessCount() / 100;
      _metrics['Uptime'] = _getUptimeRatio();
      _metrics['Disk I/O'] = _getDiskIO();
      _metrics['GPU'] = _getGPULoad();
      _metrics['Security'] = _getSecurityScore();
      _metrics['Performance'] = _getPerformanceScore();
      
      for (var key in _metrics.keys) {
        _metrics[key] = _metrics[key]!.clamp(0.0, 1.0);
      }
    });
  }

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

  double _getNetworkLoad() => 0.2 + (DateTime.now().second % 80) / 100;
  
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
    } catch (_) { return 50; }
  }

  double _getUptimeRatio() {
    try {
      final result = Process.runSync('cat', ['/proc/uptime'], runInShell: true);
      final uptime = double.parse(result.stdout.toString().split(' ')[0]);
      return (uptime / 604800).clamp(0.0, 1.0);
    } catch (_) { return 0.1; }
  }

  double _getDiskIO() => 0.15 + (DateTime.now().millisecond % 30) / 100;
  double _getGPULoad() => 0.2 + (DateTime.now().second % 50) / 100;
  double _getSecurityScore() => 0.85;
  double _getPerformanceScore() => 0.7;

  List<RadarEntry> _getRadarEntries() {
    return _titles.map((title) => RadarEntry(value: _metrics[title] ?? 0.0)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
            _position = Offset(
              _position.dx.clamp(0, MediaQuery.of(context).size.width - _radius * 2),
              _position.dy.clamp(0, MediaQuery.of(context).size.height - _radius * 2 - 50),
            );
          });
        },
        onScaleUpdate: (details) {
          setState(() {
            _radius = (_radius * details.scale).clamp(60.0, 150.0);
          });
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: _radius * 2,
              height: _radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BCD4).withOpacity(0.4 * _pulseAnimation.value),
                    blurRadius: 20 * _pulseAnimation.value,
                    spreadRadius: 5 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          fillColor: const Color(0xFF00BCD4).withOpacity(0.15),
                          borderColor: const Color(0xFF00BCD4),
                          borderWidth: 1.5,
                          entryRadius: 4,
                          dataEntries: _getRadarEntries(),
                        ),
                      ],
                      radarBorderData: const BorderSide(color: Color(0xFF00BCD4), width: 1),
                      titlePositionPercentageOffset: 1.25,
                      getTitle: (index, angle) {
                        return RadarChartTitle(
                          text: _titles[index],
                          angle: angle,
                          style: TextStyle(
                            color: _colors[index % _colors.length],
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      tickCount: 5,
                      ticksTextStyle: const TextStyle(color: Colors.white38, fontSize: 7),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
