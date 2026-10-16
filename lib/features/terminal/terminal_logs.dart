import 'dart:async';

import 'package:flutter/foundation.dart';

/// Small in-process diagnostic stream shared by TerminalService and LogsScreen.
/// Diagnostics are never written into the user's interactive PTY output.
class ZionTerminalLogs {
  ZionTerminalLogs._();

  static const int _maxEntries = 1500;
  static final List<String> _entries = <String>[];
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;
  static List<String> get entries => List<String>.unmodifiable(_entries);

  static void add(String message) {
    final line = '[Zion/Terminal] $message';
    if (_entries.length >= _maxEntries) _entries.removeAt(0);
    _entries.add(line);
    debugPrint(line);
    _controller.add(line);
  }

  static void clear() => _entries.clear();
}
