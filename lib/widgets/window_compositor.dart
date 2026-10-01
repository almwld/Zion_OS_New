import 'package:flutter/material.dart';

/// Lightweight compositor boundary for desktop windows.
class WindowCompositor extends StatefulWidget {
  final Widget child;
  const WindowCompositor({super.key, required this.child});
  @override
  State<WindowCompositor> createState() => _WindowCompositorState();
}

class _WindowCompositorState extends State<WindowCompositor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..forward();
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _scale = Tween<double>(begin: .985, end: 1.0)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    ),
  );
}
