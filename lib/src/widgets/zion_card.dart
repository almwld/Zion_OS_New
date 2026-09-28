import 'package:flutter/material.dart';

class ZionCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;

  const ZionCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            )
          : Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
