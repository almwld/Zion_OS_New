import 'package:flutter/material.dart';

import 'features/terminal/terminal_screen.dart';

/// Legacy compatibility entry point for the canonical PTY terminal.
@Deprecated('Use TerminalScreen instead.')
class CosmicTerminal extends StatelessWidget {
  const CosmicTerminal({super.key});

  @override
  Widget build(BuildContext context) => const TerminalScreen();
}
