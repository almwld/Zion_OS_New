import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/preferences_service.dart';

/// Live network radar. Every plotted value comes from Android's
/// TrafficStats/ConnectivityManager stream; no demo devices or synthetic values.
class RadarWidget extends StatefulWidget {
  const RadarWidget({super.key});

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget>
    with SingleTickerProviderStateMixin {
  static const EventChannel _channel = EventChannel('zion.os/network/radar');

  late final AnimationController _scanAnimation;
  late final Animation<double> _scanRotation;
  StreamSubscription<dynamic>? _subscription;
  Map<String, dynamic> _telemetry = <String, dynamic>{};
  String? _selectedPoint;
  bool _isExpanded = false;
  String? _streamError;

  @override
  void initState() {
    super.initState();
    _scanAnimation = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _scanRotation = Tween<double>(begin: 0, end: math.pi * 2)
        .animate(_scanAnimation);
    _listenToTelemetry();
  }

  void _listenToTelemetry() {
    _subscription = _channel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;
        final data = Map<String, dynamic>.from(event);
        // Network lifecycle notifications contain no counters. Keep the last
        // actual sample until the next periodic telemetry sample arrives.
        if (data['event'] == true && data.length <= 4) {
          if (mounted) setState(() {});
          return;
        }
        if (!mounted) return;
        setState(() {
          _telemetry = data;
          _streamError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _streamError = 'تعذر الوصول إلى قياسات الشبكة الفعلية');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scanAnimation.dispose();
    super.dispose();
  }

  double _number(String key) {
    final value = _telemetry[key];
    if (value is num) return value.toDouble();
    return 0;
  }

  String _fmtRate(String key) {
    final bytes = _number(key);
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
    return '${bytes.toStringAsFixed(0)} B/s';
  }

  List<RadarDataPoint> get _points {
    if (_telemetry.isEmpty) return const <RadarDataPoint>[];
    final transport = (_telemetry['transport'] ?? 'none').toString();
    final rx = _number('rxBytesPerSec');
    final tx = _number('txBytesPerSec');
    final rxPackets = _number('rxPacketsPerSec');
    final txPackets = _number('txPacketsPerSec');
    final down = _number('downstreamKbps');
    final up = _number('upstreamKbps');
    final rssiValue = _telemetry['wifiRssi'];
    final linkValue = _telemetry['wifiLinkSpeedMbps'];

    final points = <RadarDataPoint>[
      RadarDataPoint(
        name: 'التنزيل',
        angle: 0,
        value: _normalize(rx, 10 * 1024 * 1024),
        color: Colors.cyanAccent,
        detail: 'المعدل الفعلي: ${_fmtRate('rxBytesPerSec')}',
      ),
      RadarDataPoint(
        name: 'الرفع',
        angle: 45,
        value: _normalize(tx, 5 * 1024 * 1024),
        color: Colors.greenAccent,
        detail: 'المعدل الفعلي: ${_fmtRate('txBytesPerSec')}',
      ),
      RadarDataPoint(
        name: 'حزم واردة',
        angle: 90,
        value: _normalize(rxPackets, 5000),
        color: Colors.lightBlueAccent,
        detail: '${rxPackets.toStringAsFixed(0)} حزمة/ث',
      ),
      RadarDataPoint(
        name: 'حزم صادرة',
        angle: 135,
        value: _normalize(txPackets, 5000),
        color: Colors.orangeAccent,
        detail: '${txPackets.toStringAsFixed(0)} حزمة/ث',
      ),
      RadarDataPoint(
        name: 'سرعة التنزيل',
        angle: 180,
        value: _normalize(down, 100000),
        color: Colors.purpleAccent,
        detail: 'تقدير واجهة الشبكة: ${down.toStringAsFixed(0)} Kbit/s',
      ),
      RadarDataPoint(
        name: 'سرعة الرفع',
        angle: 225,
        value: _normalize(up, 50000),
        color: Colors.pinkAccent,
        detail: 'تقدير واجهة الشبكة: ${up.toStringAsFixed(0)} Kbit/s',
      ),
    ];
    if (transport == 'wifi' && rssiValue is num) {
      points.add(RadarDataPoint(
        name: 'إشارة Wi-Fi',
        angle: 270,
        value: _normalize((rssiValue.toDouble() + 100).clamp(0, 70), 70),
        color: Colors.yellowAccent,
        detail: 'RSSI: ${rssiValue.toStringAsFixed(0)} dBm'
            '${linkValue is num ? ' • رابط ${linkValue.toStringAsFixed(0)} Mbps' : ''}',
      ));
    }
    points.add(RadarDataPoint(
      name: 'اتصال الإنترنت',
      angle: 315,
      value: _telemetry['validated'] == true ? 1 : 0,
      color: _telemetry['validated'] == true ? Colors.green : Colors.redAccent,
      detail: 'النقل: $transport • '
          '${_telemetry['validated'] == true ? 'اتصال متحقق' : 'غير متحقق'}',
    ));
    return points;
  }

  double _normalize(double value, double ceiling) =>
      (value / ceiling).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final screen = MediaQuery.sizeOf(context);
    final width = _isExpanded ? screen.width * 0.9 : 180.0;
    final height = _isExpanded ? screen.height * 0.68 : 180.0;
    final points = _points;
    RadarDataPoint? selected;\n    for (final point in points) {\n      if (point.name == _selectedPoint) {\n        selected = point;\n        break;\n      }\n    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: prefs.isDarkMode
            ? Colors.black.withOpacity(0.88)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyan.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: RadarPainter(
                  scanRotation: _scanRotation.value,
                  showSweep: !_isExpanded,
                ),
              ),
            ),
            if (points.isNotEmpty)
              ...points.map((point) {
                final center = Offset(width / 2, height / 2);
                final radius = math.max(8.0, math.min(width, height) / 2 - 28);
                final angle = point.angle * math.pi / 180;
                final distance = radius * (0.28 + point.value * 0.62);
                final p = Offset(
                  center.dx + math.sin(angle) * distance,
                  center.dy - math.cos(angle) * distance,
                );
                return Positioned(
                  left: (p.dx - 6).clamp(0.0, width - 12),
                  top: (p.dy - 6).clamp(0.0, height - 12),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedPoint = _selectedPoint == point.name ? null : point.name;
                    }),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: point.color,
                        boxShadow: [
                          BoxShadow(
                            color: point.color.withOpacity(0.65),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            Positioned(
              top: 3,
              right: 3,
              child: IconButton(
                tooltip: _isExpanded ? 'تصغير الرادار' : 'توسيع الرادار',
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded ? Icons.compress : Icons.open_in_full,
                  size: 16,
                  color: Colors.cyan,
                ),
              ),
            ),
            Positioned(
              left: 9,
              top: 9,
              right: 30,
              child: Text(
                'رادار الشبكة الحي',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 11 * prefs.fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_telemetry.isEmpty || _streamError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _streamError ?? 'بانتظار أول عينة من النظام…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: prefs.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 11 * prefs.fontScale,
                    ),
                  ),
                ),
              ),
            if (_isExpanded && selected != null)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: prefs.isDarkMode ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected.color.withOpacity(0.7)),
                  ),
                  child: Text(
                    '${selected.name}  •  ${selected.detail}',
                    style: TextStyle(
                      color: prefs.isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 11 * prefs.fontScale,
                    ),
                  ),
                ),
              ),
            if (_isExpanded)
              Positioned(
                left: 10,
                right: 10,
                bottom: selected == null ? 8 : 58,
                child: Text(
                  'RX ${_fmtRate('rxBytesPerSec')}   •   TX ${_fmtRate('txBytesPerSec')}\n'
                  'الواجهة: ${_telemetry['interface'] ?? '—'}   •   IP: ${_telemetry['ipAddress'] ?? '—'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: prefs.isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 10 * prefs.fontScale,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RadarDataPoint {
  const RadarDataPoint({
    required this.name,
    required this.angle,
    required this.value,
    required this.color,
    required this.detail,
  });

  final String name;
  final double angle;
  final double value;
  final Color color;
  final String detail;
}

class RadarPainter extends CustomPainter {
  const RadarPainter({required this.scanRotation, required this.showSweep});

  final double scanRotation;
  final bool showSweep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(0.0, math.min(size.width, size.height) / 2 - 12);
    final rings = Paint()
      ..color = const Color(0x5536D9C5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, rings);
    }
    final axis = Paint()
      ..color = const Color(0x3336D9C5)
      ..strokeWidth = 1;
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        center,
        Offset(center.dx + math.sin(angle) * radius,
            center.dy - math.cos(angle) * radius),
        axis,
      );
    }
    if (showSweep) {
      final angle = scanRotation;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + math.sin(angle) * radius,
            center.dy - math.cos(angle) * radius)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2 + angle,
          0.22,
          false,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x3036D9C5)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) =>
      oldDelegate.scanRotation != scanRotation ||
      oldDelegate.showSweep != showSweep;
}
