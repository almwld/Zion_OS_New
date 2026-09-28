import 'package:flutter/material.dart';

class ZionGradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  const ZionGradientText({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.fontWeight = FontWeight.bold,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [Colors.green, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: Colors.white),
      ),
    );
  }
}

class ZionIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const ZionIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(size * 0.3),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.green, Colors.green.shade700]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8)],
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

class ZionGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ZionGlassCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: child,
      ),
    );
  }
}
