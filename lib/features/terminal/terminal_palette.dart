import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

/// Coordinated UI + xterm palette presets. Zion Teal remains the default.
class TerminalPalette {
  const TerminalPalette({
    required this.name,
    required this.description,
    required this.background,
    required this.surface,
    required this.foreground,
    required this.accent,
    required this.cursor,
    required this.selection,
  });

  final String name;
  final String description;
  final Color background;
  final Color surface;
  final Color foreground;
  final Color accent;
  final Color cursor;
  final Color selection;

  static const zion = TerminalPalette(
    name: 'Zion Teal', description: 'هوية Zion الافتراضية',
    background: Color(0xFF090B0A), surface: Color(0xFF101715),
    foreground: Color(0xFFDCE7E0), accent: Color(0xFF19D3C5),
    cursor: Color(0xFF19D3C5), selection: Color(0xFF24443F),
  );
  static const matrix = TerminalPalette(
    name: 'Matrix', description: 'أخضر على الأسود',
    background: Color(0xFF000000), surface: Color(0xFF0A0A0A),
    foreground: Color(0xFF00FF41), accent: Color(0xFF00FF41),
    cursor: Color(0xFF00FF41), selection: Color(0xFF003B00),
  );
  static const dracula = TerminalPalette(
    name: 'Dracula', description: 'بنفسجي داكن',
    background: Color(0xFF282A36), surface: Color(0xFF1E1F29),
    foreground: Color(0xFFF8F8F2), accent: Color(0xFFBD93F9),
    cursor: Color(0xFFFF79C6), selection: Color(0xFF44475A),
  );
  static const nord = TerminalPalette(
    name: 'Nord', description: 'ألوان باردة هادئة',
    background: Color(0xFF2E3440), surface: Color(0xFF3B4252),
    foreground: Color(0xFFD8DEE9), accent: Color(0xFF88C0D0),
    cursor: Color(0xFF88C0D0), selection: Color(0xFF434C5E),
  );
  static const solarized = TerminalPalette(
    name: 'Solarized Dark', description: 'تباين منخفض مريح',
    background: Color(0xFF002B36), surface: Color(0xFF073642),
    foreground: Color(0xFF839496), accent: Color(0xFF268BD2),
    cursor: Color(0xFF93A1A1), selection: Color(0xFF073642),
  );
  static const cyberpunk = TerminalPalette(
    name: 'Cyberpunk', description: 'سماوي ووردي',
    background: Color(0xFF0D0221), surface: Color(0xFF1A0F2E),
    foreground: Color(0xFFFFEAF4), accent: Color(0xFF00F5FF),
    cursor: Color(0xFFFF006E), selection: Color(0xFF3D1E6D),
  );
  static const ubuntu = TerminalPalette(
    name: 'Ubuntu', description: 'عنابي داكن',
    background: Color(0xFF300A24), surface: Color(0xFF2C001E),
    foreground: Color(0xFFFFFFFF), accent: Color(0xFFE95420),
    cursor: Color(0xFFBBBBBB), selection: Color(0xFF444444),
  );
  static const ocean = TerminalPalette(
    name: 'Ocean', description: 'أزرق بحري',
    background: Color(0xFF001E3C), surface: Color(0xFF002A4A),
    foreground: Color(0xFFB0D8F0), accent: Color(0xFF00D4FF),
    cursor: Color(0xFF00D4FF), selection: Color(0xFF004B7A),
  );

  static const all = <TerminalPalette>[
    zion, matrix, dracula, nord, solarized, cyberpunk, ubuntu, ocean,
  ];

  TerminalTheme toXtermTheme() => TerminalTheme(
    cursor: cursor,
    selection: selection,
    foreground: foreground,
    background: background,
    black: const Color(0xFF000000),
    white: foreground,
    red: const Color(0xFFCC6666),
    green: accent,
    yellow: const Color(0xFFE5C07B),
    blue: const Color(0xFF61AFEF),
    magenta: const Color(0xFFC678DD),
    cyan: accent,
    brightBlack: const Color(0xFF5C6370),
    brightRed: const Color(0xFFFF6B6B),
    brightGreen: accent,
    brightYellow: const Color(0xFFFFD580),
    brightBlue: const Color(0xFF82AAFF),
    brightMagenta: const Color(0xFFD7AFFF),
    brightCyan: accent,
    brightWhite: foreground,
    searchHitBackground: selection,
    searchHitBackgroundCurrent: accent,
    searchHitForeground: background,
  );
}
