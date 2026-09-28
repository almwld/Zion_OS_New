import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Real-time Flutter 3D perspective panel. No image/video simulation is used.
class Holographic3DPanel extends StatefulWidget {
  const Holographic3DPanel({super.key, required this.child});
  final Widget child;

  @override
  State<Holographic3DPanel> createState() => _Holographic3DPanelState();
}

class _Holographic3DPanelState extends State<Holographic3DPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = math.sin(_controller.value * math.pi * 2) * 0.045;
        final perspective = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(angle)
          ..rotateY(angle * 1.4);
        return Transform(
          alignment: Alignment.center,
          transform: perspective,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 28,
                  spreadRadius: 1,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
