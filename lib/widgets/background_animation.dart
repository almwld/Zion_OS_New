import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final AnimationType type;
  final double opacity;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.type = AnimationType.particle,
    this.opacity = 0.1,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(),
        widget.child,
      ],
    );
  }

  Widget _buildBackground() {
    switch (widget.type) {
      case AnimationType.particle:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(_controller.value, widget.opacity),
              size: Size.infinite,
            );
          },
        );
      case AnimationType.wave:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(_controller.value, widget.opacity),
              size: Size.infinite,
            );
          },
        );
      case AnimationType.matrix:
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: MatrixRainPainter(_controller.value, widget.opacity),
              size: Size.infinite,
            );
          },
        );
      default:
        return Container(color: Colors.transparent);
    }
  }
}

enum AnimationType { particle, wave, matrix }

class ParticlePainter extends CustomPainter {
  final double progress;
  final double opacity;
  final Random _random = Random();

  ParticlePainter(this.progress, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BCD4).withOpacity(opacity)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = (_random.nextDouble() * size.width);
      final y = (_random.nextDouble() * size.height + progress * size.height) % size.height;
      canvas.drawCircle(Offset(x, y), 2 + _random.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WavePainter extends CustomPainter {
  final double progress;
  final double opacity;

  WavePainter(this.progress, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BCD4).withOpacity(opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (double x = 0; x < size.width; x += 10) {
      final y = size.height / 2 + sin(x * 0.02 + progress * 2 * 3.14159) * 30;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MatrixRainPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final Random _random = Random();

  MatrixRainPainter(this.progress, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BCD4).withOpacity(opacity)
      ..style = PaintingStyle.fill;

    const chars = ['0', '1', 'Z', 'I', 'O', 'N'];

    for (int i = 0; i < 200; i++) {
      final x = i * size.width / 200;
      final y = (progress * size.height + _random.nextDouble() * size.height) % size.height;
      final char = chars[_random.nextInt(chars.length)];
      
      const style = TextStyle(color: Color(0xFF00BCD4), fontSize: 12);
      final textSpan = TextSpan(text: char, style: style);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
