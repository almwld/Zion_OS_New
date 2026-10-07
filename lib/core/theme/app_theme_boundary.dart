import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_manager.dart';

/// Replaces the desktop shell theme at an application-window boundary.
///
/// The Zion desktop keeps its Cyan/Teal shell, while an opened app receives
/// the selected application palette from [ThemeManager]. This prevents the
/// shell from recoloring an app's surfaces, cards, inputs and navigation.
class AppThemeBoundary extends StatelessWidget {
  const AppThemeBoundary({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, manager, _) {
        return Theme(
          data: manager.getThemeData(),
          child: child,
        );
      },
    );
  }
}
