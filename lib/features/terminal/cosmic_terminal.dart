import 'package:flutter/material.dart';

import 'terminal_screen.dart';

/// Compatibility entry point for the legacy Cosmic Terminal surface.
///
/// The real terminal implementation is [TerminalScreen], backed by the
/// canonical TerminalService + native PTY path. Keeping this adapter avoids
/// silently presenting a static placeholder to older callers.
class CosmicTerminal extends StatelessWidget {
  const CosmicTerminal({super.key});

  @override
  Widget build(BuildContext context) => const TerminalScreen();
}
