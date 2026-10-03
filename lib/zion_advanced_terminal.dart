import 'package:flutter/material.dart';

import 'features/terminal/terminal_screen.dart';

/// Legacy compatibility surface for the canonical Zion PTY terminal.
@Deprecated('Use TerminalScreen instead.')
class ZionAdvancedTerminal extends StatelessWidget {
  const ZionAdvancedTerminal({super.key});

  @override
  Widget build(BuildContext context) => const TerminalScreen();
}
