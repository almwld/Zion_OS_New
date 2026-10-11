import 'package:flutter/material.dart';
import '../../features/terminal/terminal_screen.dart';

/// Compatibility entry point that delegates to the single real Zion PTY terminal.
/// This prevents the legacy command runner from silently using Android's host shell.
class TerminalApp extends StatelessWidget {
  const TerminalApp({super.key});

  @override
  Widget build(BuildContext context) => const TerminalScreen();
}
