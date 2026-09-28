import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadarNode {
  final String id;
  final String label;
  final double strength;
  final Offset position;
  const RadarNode({required this.id, required this.label, required this.strength, required this.position});
}

/// Visual network radar. It renders only supplied, real discovery data and
/// never invents nodes or connections.
class SpiderRadar3D extends StatelessWidget {
  final List<RadarNode> nodes;
  const SpiderRadar3D({super.key, this.nodes = const []});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpiderRadarPainter(nodes),
      child: const SizedBox.expand(),
    );
  }
}

class _SpiderRadarPainter extends CustomPainter {
  final List<RadarNode> nodes;
  const _SpiderRadarPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(0.0, math.min(size.width, size.height) / 2 - 18);

    final background = Paint()..color = const Color(0xFF071318);
    canvas.drawCircle(center, radius, background);

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
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), axis);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), axis);

    final nodePaint = Paint()..color = const Color(0xFF36D9C5);
    for (final node in nodes) {
      final p = Offset(center.dx + node.position.dx * radius, center.dy + node.position.dy * radius);
      final strength = node.strength.clamp(0.0, 1.0);
      canvas.drawCircle(p, 3 + strength * 5, nodePaint);
      final tp = TextPainter(
        text: TextSpan(text: node.label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 100);
      tp.paint(canvas, p + const Offset(7, -5));
    }
  }

  @override
  bool shouldRepaint(covariant _SpiderRadarPainter oldDelegate) => oldDelegate.nodes != nodes;
}
