import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurIntensity;
  final Color borderColor;
  final double borderWidth;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurIntensity = 10,
    this.borderColor = Colors.white,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor.withOpacity(0.3), width: borderWidth),
          ),
          child: child,
        ),
      ),
    );
  }
}

class NeumorphicButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double borderRadius;

  const NeumorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              offset: const Offset(-3, -3),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(3, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
