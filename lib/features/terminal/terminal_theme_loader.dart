import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'terminal_palette.dart';

/// Loads a Base16-style .properties palette from the packaged assets.
/// Missing or malformed optional palettes never prevent the terminal starting.
class TerminalThemeLoader {
  static Future<TerminalPalette?> loadFirstPackagedPalette() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final candidates = manifest
          .listAssets()
          .where((path) =>
              path.startsWith('assets/colors/') &&
              path.toLowerCase().endsWith('.properties'))
          .toList()
        ..sort();
      for (final assetPath in candidates) {
        try {
          final values = parseProperties(await rootBundle.loadString(assetPath));
          final background = _color(values['base00'] ?? values['background']);
          final foreground = _color(values['base05'] ?? values['foreground']);
          final accent = _color(values['base0D'] ?? values['accent']);
          if (background == null || foreground == null || accent == null) continue;
          final surface = _color(values['base01'] ?? values['surface']) ?? background;
          final selection = _color(values['base02'] ?? values['selection']) ?? surface;
          final cursor = _color(values['base0C'] ?? values['cursor']) ?? accent;
          final name = assetPath
              .split('/')
              .last
              .replaceFirst(RegExp(r'\.properties$', caseSensitive: false), '')
              .replaceAll(RegExp(r'[-_]'), ' ');
          return TerminalPalette(
            name: name.isEmpty ? 'Asset palette' : name,
            description: 'Loaded from $assetPath',
            background: background,
            surface: surface,
            foreground: foreground,
            accent: accent,
            cursor: cursor,
            selection: selection,
          );
        } on FormatException {
          // Ignore one invalid optional file and try the next palette.
        } on FlutterError {
          // Ignore assets that the current build did not package.
        }
      }
    } on FlutterError {
      // Asset manifest unavailable in older Flutter builds: keep built-in theme.
    }
    return null;
  }

  @visibleForTesting
  static Map<String, String> parseProperties(String content) {
    final result = <String, String>{};
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) continue;
      final separator = line.indexOf('=');
      final colon = line.indexOf(':');
      final index = separator < 0
          ? colon
          : (colon < 0 ? separator : (separator < colon ? separator : colon));
      if (index <= 0) continue;
      result[line.substring(0, index).trim()] = line.substring(index + 1).trim();
    }
    return result;
  }

  static Color? _color(String? value) {
    if (value == null) return null;
    var hex = value.trim().replaceFirst('#', '').replaceFirst('0x', '');
    if (hex.length == 3) {
      hex = hex.split('').map((digit) => '$digit$digit').join();
    }
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}
