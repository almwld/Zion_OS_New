import 'package:flutter/material.dart';
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

  final List<RadarDataPoint> _points = [
    RadarDataPoint(name: 'المنفذ 80 - HTTP', angle: 0, value: 85, color: Colors.green, activity: 'نشاط عالي', packets: 12450, responseTime: '23ms'),
    RadarDataPoint(name: 'المنفذ 443 - HTTPS', angle: 45, value: 92, color: Colors.yellow, activity: 'نشاط عالي جداً', packets: 89200, responseTime: '45ms'),
    RadarDataPoint(name: 'المنفذ 22 - SSH', angle: 90, value: 45, color: Colors.red, activity: 'نشاط متوسط', packets: 3200, responseTime: '12ms'),
    RadarDataPoint(name: 'المنفذ 3306 - MySQL', angle: 135, value: 67, color: Colors.purple, activity: 'نشاط مرتفع', packets: 56700, responseTime: '67ms'),
    RadarDataPoint(name: 'المنفذ 8080 - Proxy', angle: 180, value: 34, color: Colors.blue, activity: 'نشاط منخفض', packets: 890, responseTime: '234ms'),
    RadarDataPoint(name: 'المنفذ 53 - DNS', angle: 225, value: 78, color: Colors.orange, activity: 'نشاط مرتفع', packets: 34500, responseTime: '8ms'),
    RadarDataPoint(name: 'المنفذ 25 - SMTP', angle: 270, value: 23, color: Colors.white, activity: 'نشاط منخفض جداً', packets: 120, responseTime: '345ms'),
    RadarDataPoint(name: 'المنفذ 161 - SNMP', angle: 315, value: 56, color: Colors.teal, activity: 'نشاط متوسط', packets: 8900, responseTime: '56ms'),
  ];

  @override
  void initState() {
    super.initState();
    _scanAnimation = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _scanRotation = Tween<double>(begin: 0, end: 360).animate(_scanAnimation);
  }

  @override
  void dispose() {
    _scanAnimation.dispose();
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
            
            // Points
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

  double _getX(double angle, double size) {
    double center = size / 2;
    double radius = size / 2 - 20;
    return center + radius * (angle - 90) * 3.14159 / 180;
  }

  double _getY(double angle, double size) {
    double center = size / 2;
    double radius = size / 2 - 20;
    return center + radius * angle * 3.14159 / 180;
  }

  List<String> _getPointData(String pointName) {
    final point = _points.firstWhere((p) => p.name == pointName);
    return [
      'قوة الإشارة: ${point.value}%',
      'النشاط: ${point.activity}',
      'عدد الحزم: ${point.packets}',
      'سرعة الاستجابة: ${point.responseTime}',
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
        center.dx + radius * (angle - 90),
        center.dy + radius * angle,
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
        center.dx + radius * (angle - 90),
        center.dy + radius * angle,
      );
      path.lineTo(
        center.dx + radius * (angle - 90) * 0.5,
        center.dy + radius * angle * 0.5,
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
