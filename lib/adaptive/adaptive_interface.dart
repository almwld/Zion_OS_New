import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

/// Applies a presentation theme to the supplied subtree according to the
/// current operational mode. Modes change presentation and available UX hints;
/// they do not grant elevated privileges or enable offensive execution.
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
    switch (mode) {
      case OperationMode.defensive:
        return base.copyWith(colorScheme: scheme.copyWith(primary: Colors.blue, secondary: Colors.cyan));
      case OperationMode.analysis:
        return base.copyWith(colorScheme: scheme.copyWith(primary: Colors.teal, secondary: Colors.green));
      case OperationMode.tools:
        return base.copyWith(colorScheme: scheme.copyWith(primary: Colors.indigo, secondary: Colors.lightBlue));
      case OperationMode.stealth:
        return base.copyWith(colorScheme: scheme.copyWith(primary: Colors.blueGrey, secondary: Colors.grey));
    }
  }
}
