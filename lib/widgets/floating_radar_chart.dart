import 'dart:async';
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../src/core/services/system_metrics.dart';

class FloatingRadarChart extends StatefulWidget {
  final VoidCallback onClose;
  const FloatingRadarChart({super.key, required this.onClose});

  @override
  State<FloatingRadarChart> createState() => _FloatingRadarChartState();
}

class _FloatingRadarChartState extends State<FloatingRadarChart> {
  Offset _position = Offset.zero;
  double _width = 280;
  double _height = 280;
  Timer? _updateTimer;
  final Battery _battery = Battery();
  final Map<String, double> _metrics = {
    'CPU': 0.0, 'RAM': 0.0, 'Storage': 0.0, 'Battery': 0.0,
    'RX': 0.0, 'TX': 0.0, 'Temp': 0.0, 'Processes': 0.0, 'Uptime': 0.0,
  };
  final List<String> _titles = const [
    'CPU', 'RAM', 'Storage', 'Battery', 'RX', 'TX', 'Temp', 'Processes', 'Uptime'
  ];
  Map<String, dynamic> _network = <String, dynamic>{};
  StreamSubscription<dynamic>? _networkSubscription;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      setState(() {
        _position = Offset(
          (size.width - _width - 20).clamp(0.0, double.infinity),
          (size.height - _height - 100).clamp(0.0, double.infinity),
        );
      });
      _networkSubscription = const EventChannel('zion.os/network/radar')
          .receiveBroadcastStream()
          .listen((dynamic event) {
        if (event is! Map || !mounted) return;
        setState(() => _network = Map<String, dynamic>.from(event));
      }, onError: (_) {});
      _startRealTimeUpdates();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _updateMetrics();
    });
  }

  Future<void> _updateMetrics() async {
    if (!mounted) return;
    try {
      final metrics = await SystemMetrics.read();
      int? batteryLevel;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {}
      final rx = (_network['rxBytesPerSec'] as num?)?.toDouble() ?? 0.0;
      final tx = (_network['txBytesPerSec'] as num?)?.toDouble() ?? 0.0;
      double rateScale(double value) =>
          (math.log(1 + value.clamp(0.0, 1000000000.0)) / math.log(1 + 5 * 1024 * 1024))
              .clamp(0.0, 1.0).toDouble();
      if (!mounted) return;
      setState(() {
        _metrics['CPU'] = metrics.cpuPercent / 100;
        _metrics['RAM'] = metrics.memoryPercent / 100;
        _metrics['Storage'] = metrics.storagePercent / 100;
        _metrics['Battery'] = (batteryLevel ?? 0) / 100;
        _metrics['RX'] = rateScale(rx);
        _metrics['TX'] = rateScale(tx);
        _metrics['Temp'] = metrics.temperatureCelsius <= 0
            ? 0.0
            : ((metrics.temperatureCelsius - 20) / 60).clamp(0.0, 1.0).toDouble();
        _metrics['Processes'] = (metrics.processCount / 500).clamp(0.0, 1.0).toDouble();
        _metrics['Uptime'] = (metrics.uptime.inSeconds / 86400).clamp(0.0, 1.0).toDouble();
        _lastUpdated = DateTime.now();
      });
    } catch (_) {
      // Leave the last valid telemetry visible; never replace it with invented data.
    }
  }

  String _rateLabel(String key) {
    final value = (_network[key] as num?)?.toDouble();
    if (value == null || value < 0) return 'غير متاح';
    if (value >= 1024 * 1024) return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    if (value >= 1024) return '${(value / 1024).toStringAsFixed(1)} KB/s';
    return '${value.toStringAsFixed(0)} B/s';
  }

  List<RadarEntry> _getRadarEntries() =>
      _titles.map((title) => RadarEntry(value: _metrics[title] ?? 0.0)).toList();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxLeft = (size.width - _width).clamp(0.0, double.infinity);
    final maxTop = (size.height - _height - 50).clamp(0.0, double.infinity);
    final left = _position.dx.clamp(0.0, maxLeft);
    final top = _position.dy.clamp(0.0, maxTop);

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.6), width: 1.5),
          ),
          child: Column(
            children: [
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _position += details.delta;
                    _position = Offset(
                      _position.dx.clamp(0.0, maxLeft),
                      _position.dy.clamp(0.0, maxTop),
                    );
                  });
                },
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.radar, color: Color(0xFF00BCD4), size: 18),
                      const SizedBox(width: 8),
                      const Text('Live system telemetry', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() { _width = 48; _height = 48; }),
                        child: const Icon(Icons.minimize, color: Color(0xFF00BCD4), size: 18),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close, color: Color(0xFF00BCD4), size: 18),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  'CPU ${(_metrics['CPU']! * 100).round()}%  RAM ${(_metrics['RAM']! * 100).round()}%  RX ${_rateLabel('rxBytesPerSec')}  TX ${_rateLabel('txBytesPerSec')}' +
                      (_lastUpdated == null ? '  • بانتظار القياسات' : '  • ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onScaleUpdate: (details) {
                    setState(() {
                      _width = (_width * details.scale).clamp(120.0, 500.0);
                      _height = (_height * details.scale).clamp(120.0, 500.0);
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
                      getTitle: (index, angle) => RadarChartTitle(text: _titles[index], angle: angle),
                    ),
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
