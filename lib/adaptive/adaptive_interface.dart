import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/zion_colors.dart';

enum OperationMode { defensive, analysis, tools, stealth }

class ModeProvider extends ChangeNotifier {
  OperationMode _currentMode = OperationMode.analysis;
  OperationMode get currentMode => _currentMode;

  void setMode(OperationMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    notifyListeners();
  }

  void toggleMode() {
    final values = OperationMode.values;
    final next = (values.indexOf(_currentMode) + 1) % values.length;
    setMode(values[next]);
  }
}

/// Operational mode changes semantic accents without replacing the stable
/// Zion shell palette.
class AdaptiveInterface extends StatelessWidget {
  final Widget child;
  const AdaptiveInterface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ModeProvider>().currentMode;
    return Theme(data: _themeFor(mode, Theme.of(context)), child: child);
  }

  ThemeData _themeFor(OperationMode mode, ThemeData base) {
    final scheme = base.colorScheme;
    final primary = switch (mode) {
      OperationMode.defensive => ZionColors.cyan,
      OperationMode.analysis => ZionColors.cyan,
      OperationMode.tools => ZionColors.cyan,
      OperationMode.stealth => ZionColors.cyan,
    };
    return base.copyWith(
      colorScheme: scheme.copyWith(primary: primary, secondary: ZionColors.teal),
      primaryColor: primary,
      iconTheme: base.iconTheme.copyWith(color: primary),
    );
  }
}
