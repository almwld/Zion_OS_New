import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';

class RadarWidget extends StatefulWidget {
  const RadarWidget({super.key});

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimation;
  late Animation<double> _scanRotation;
  bool _isExpanded = false;
  String? _selectedPoint;

  List<RadarDataPoint> _points = <RadarDataPoint>[];
  StreamSubscription<dynamic>? _radarSubscription;
  Map<String, dynamic> _telemetry = <String, dynamic>{};
  String? _telemetryError;

  @override
  void initState() {
    super.initState();
    _scanAnimation = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _scanRotation = Tween<double>(begin: 0, end: 360).animate(_scanAnimation);
    _radarSubscription = const EventChannel('zion.os/network/radar')
        .receiveBroadcastStream()
        .listen((dynamic event) {
      if (event is! Map || !mounted) return;
      final data = Map<String, dynamic>.from(event);
      if (!data.containsKey('rxBytesPerSec')) {
        setState(() => _telemetry.addAll(data));
        return;
      }
      setState(() {
        _telemetry = data;
        _points = _buildPoints(data);
        _telemetryError = null;
      });
    }, onError: (Object error) {
      if (mounted) setState(() => _telemetryError = 'تعذر استقبال بيانات الشبكة: $error');
    });
  }

  @override
  void dispose() {
    _scanAnimation.dispose();
    _radarSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isExpanded ? MediaQuery.of(context).size.width * 0.9 : 180,
      height: _isExpanded ? MediaQuery.of(context).size.height * 0.7 : 180,
      decoration: BoxDecoration(
        color: prefs.isDarkMode ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.cyan.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Radar Background
            CustomPaint(
              painter: RadarPainter(
                points: _points,
                scanRotation: _scanRotation.value,
                isExpanded: _isExpanded,
              ),
              size: Size.infinite,
            ),
            
            if (_points.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _telemetryError ?? 'بانتظار بيانات الشبكة الحية من Android',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: prefs.isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12 * prefs.fontScale),
                  ),
                ),
              ),
            // Points from native network telemetry only.
            ..._points.map((point) => Positioned(
              left: _getX(point.angle, _isExpanded ? MediaQuery.of(context).size.width * 0.9 : 180),
              top: _getY(point.angle, _isExpanded ? MediaQuery.of(context).size.height * 0.7 : 180),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPoint = _selectedPoint == point.name ? null : point.name),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: point.color,
                    boxShadow: [
                      BoxShadow(
                        color: point.color.withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
            
            // Info Card for Selected Point
            if (_selectedPoint != null)
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: prefs.isDarkMode ? Colors.grey[900] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPoint!,
                        style: TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12 * prefs.fontScale,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ..._getPointData(_selectedPoint!).map((data) => Text(
                        data,
                        style: TextStyle(
                          color: prefs.isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 10 * prefs.fontScale,
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            
            // Expand/Collapse Button
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded ? Icons.compress : Icons.open_in_full,
                  size: 16,
                  color: Colors.cyan,
                ),
              ),
            ),
            
            // Scan Line
            if (!_isExpanded)
              AnimatedBuilder(
                animation: _scanRotation,
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _scanRotation.value * 3.14159 / 180,
                    child: Container(
                      width: 2,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.cyan.withOpacity(0.8), Colors.cyan.withOpacity(0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  List<RadarDataPoint> _buildPoints(Map<String, dynamic> data) {
    final rx = (data['rxBytesPerSec'] as num?)?.toDouble();
    final tx = (data['txBytesPerSec'] as num?)?.toDouble();
    final rxPackets = (data['rxPacketsPerSec'] as num?)?.toDouble();
    final txPackets = (data['txPacketsPerSec'] as num?)?.toDouble();
    final down = (data['downstreamKbps'] as num?)?.toDouble();
    final up = (data['upstreamKbps'] as num?)?.toDouble();
    final rssi = (data['wifiRssi'] as num?)?.toDouble();
    final raw = <({String name, double angle, double value, Color color, double actual, String unit})>[
      if (rx != null && rx >= 0) (name: 'استقبال الشبكة', angle: 0, value: _normalize(rx, 5 * 1024 * 1024), color: Colors.green, actual: rx, unit: 'B/s'),
      if (tx != null && tx >= 0) (name: 'إرسال الشبكة', angle: 60, value: _normalize(tx, 5 * 1024 * 1024), color: Colors.cyan, actual: tx, unit: 'B/s'),
      if (rxPackets != null && rxPackets >= 0) (name: 'حزم مستقبلة', angle: 120, value: _normalize(rxPackets, 1000), color: Colors.teal, actual: rxPackets, unit: 'حزمة/ث'),
      if (txPackets != null && txPackets >= 0) (name: 'حزم مرسلة', angle: 180, value: _normalize(txPackets, 1000), color: Colors.orange, actual: txPackets, unit: 'حزمة/ث'),
      if (down != null && down >= 0) (name: 'سرعة التنزيل المعلنة', angle: 240, value: _normalize(down, 100000), color: Colors.blue, actual: down, unit: 'Kbps'),
      if (up != null && up >= 0) (name: 'سرعة الرفع المعلنة', angle: 300, value: _normalize(up, 100000), color: Colors.purple, actual: up, unit: 'Kbps'),
      if (rssi != null && rssi >= -120 && rssi <= 0) (name: 'قوة Wi-Fi', angle: 330, value: _normalize(rssi + 120, 120), color: Colors.yellow, actual: rssi, unit: 'dBm'),
    ];
    return raw.map((p) => RadarDataPoint(
      name: p.name,
      angle: p.angle,
      value: p.value,
      color: p.color,
      activity: p.actual > 0 ? 'مرصود فعلياً' : 'لا يوجد نشاط مرصود',
      packets: p.actual.round(),
      responseTime: p.actual.toStringAsFixed(0) + ' ' + p.unit,
    )).toList();
  }

  double _normalize(double value, double scale) =>
      (value.abs() / scale).clamp(0.0, 1.0).toDouble() * 100;


  double _getX(double angle, double size) {
    final center = size / 2;
    final radius = size / 2 - 20;
    final radians = angle * math.pi / 180;
    return center + radius * math.cos(radians);
  }

  double _getY(double angle, double size) {
    final center = size / 2;
    final radius = size / 2 - 20;
    final radians = angle * math.pi / 180;
    return center + radius * math.sin(radians);
  }

  List<String> _getPointData(String pointName) {
    final point = _points.firstWhere((p) => p.name == pointName);
    return [
      'مؤشر النشاط: ${point.value.toStringAsFixed(0)}%',
      'النشاط: ${point.activity}',
      'القيمة المرصودة: ${point.packets}',
      'المعدل الحالي: ${point.responseTime}',
    ];
  }
}

class RadarDataPoint {
  final String name;
  final double angle;
  final double value;
  final Color color;
  final String activity;
  final int packets;
  final String responseTime;

  RadarDataPoint({
    required this.name,
    required this.angle,
    required this.value,
    required this.color,
    required this.activity,
    required this.packets,
    required this.responseTime,
  });
}

class RadarPainter extends CustomPainter {
  final List<RadarDataPoint> points;
  final double scanRotation;
  final bool isExpanded;

  RadarPainter({
    required this.points,
    required this.scanRotation,
    required this.isExpanded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 20;
    
    // Draw circles
    final circlePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, circlePaint);
    }
    
    // Draw radial lines
    final linePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..strokeWidth = 1;
    
    for (int i = 0; i < 8; i++) {
      double angle = i * 45 * 3.14159 / 180;
      Offset end = Offset(
        center.dx + radius * math.cos(angle - math.pi / 2),
        center.dy + radius * math.sin(angle - math.pi / 2),
      );
      canvas.drawLine(center, end, linePaint);
    }
    
    // Draw scan wave
    if (!isExpanded) {
      final scanPaint = Paint()
        ..color = Colors.cyan.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      
      double angle = scanRotation * 3.14159 / 180;
      Path path = Path();
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + radius * math.cos(angle - math.pi / 2),
        center.dy + radius * math.sin(angle - math.pi / 2),
      );
      path.lineTo(
        center.dx + radius * 0.5 * math.cos(angle - math.pi / 2),
        center.dy + radius * 0.5 * math.sin(angle - math.pi / 2),
      );
      path.close();
      canvas.drawPath(path, scanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.scanRotation != scanRotation || oldDelegate.isExpanded != isExpanded;
  }
}
