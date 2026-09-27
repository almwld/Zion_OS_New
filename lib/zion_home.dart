import 'package:flutter/material.dart';
import 'dart:math';
import 'arsenal_drawer.dart';
import 'features/terminal/terminal_screen.dart';

class ZionHome extends StatefulWidget {
  const ZionHome({super.key});

  @override
  State<ZionHome> createState() => _ZionHomeState();
}

class _ZionHomeState extends State<ZionHome> with TickerProviderStateMixin {
  late AnimationController _matrixController;

  @override
  void initState() {
    super.initState();
    _matrixController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _matrixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Matrix Rain Background
          AnimatedBuilder(
            animation: _matrixController,
            builder: (context, child) {
              return CustomPaint(
                painter: MatrixRainPainter(_matrixController.value),
                size: MediaQuery.of(context).size,
              );
            },
          ),
          // Main Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FF41), width: 3),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00FF41).withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: const Center(
                    child: Text('ن', style: TextStyle(color: Color(0xFF00FF41), fontSize: 60, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Zion Launcher', style: TextStyle(color: const Color(0xFF00FF41).withOpacity(0.9), fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Cairo', letterSpacing: 4)),
                const Spacer(flex: 1),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(icon: Icons.auto_awesome, label: 'مُدَبِّر', onTap: () {}),
                      _ActionButton(icon: Icons.shield, label: 'الترسانة', onTap: () => _openArsenal(context)),
                      _ActionButton(icon: Icons.terminal, label: 'الطرفية', onTap: () => _openTerminal(context)),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openArsenal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ArsenalDrawer(),
    );
  }

  void _openTerminal(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const TerminalScreen()));
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Icon(widget.icon, color: const Color(0xFF00FF41), size: 40),
            const SizedBox(height: 8),
            Text(widget.label, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 14, fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }
}

class MatrixRainPainter extends CustomPainter {
  final double time;
  final List<_RainColumn> _columns = [];
  final Random _random = Random();

  MatrixRainPainter(this.time) {
    if (_columns.isEmpty) {
      for (int i = 0; i < 50; i++) {
        _columns.add(_RainColumn(_random));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00FF41).withOpacity(0.15);
    for (final col in _columns) {
      col.update(time, size.height);
      for (final char in col.chars) {
        paint.color = const Color(0xFF00FF41).withOpacity(char.opacity);
        final textPainter = TextPainter(
          text: TextSpan(text: char.char, style: TextStyle(color: paint.color, fontSize: 14, fontFamily: 'monospace')),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(col.x, char.y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RainColumn {
  final double x;
  final double speed;
  final List<_RainChar> chars = [];
  final Random _random;

  _RainColumn(this._random) : x = _random.nextDouble() * 500, speed = _random.nextDouble() * 2 + 1 {
    _initChars(800);
  }

  void _initChars(double maxHeight) {
    final count = _random.nextInt(15) + 5;
    for (int i = 0; i < count; i++) {
      chars.add(_RainChar(_random, -_random.nextDouble() * maxHeight));
    }
  }

  void update(double time, double maxHeight) {
    for (final char in chars) {
      char.y += speed;
      char.opacity = (0.1 + 0.2 * (char.y / maxHeight)).clamp(0.05, 0.3);
      if (char.y > maxHeight) {
        char.y = 0;
        char.char = _randomChar();
      }
    }
  }

  String _randomChar() {
    const chars = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي';
    return chars[_random.nextInt(chars.length)];
  }
}

class _RainChar {
  double y;
  double opacity;
  String char;
  _RainChar(Random random, this.y)
      : opacity = 0.1 + random.nextDouble() * 0.2,
        char = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي'[random.nextInt(36)];
}
