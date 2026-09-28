import 'package:flutter/material.dart';

class ZionWindow {
  final String id;
  final String title;
  final Widget content;
  double x, y;
  double width, height;
  bool isMinimized;
  bool isMaximized;
  bool isClosed;

  ZionWindow({
    required this.id,
    required this.title,
    required this.content,
    this.x = 50,
    this.y = 50,
    this.width = 600,
    this.height = 400,
    this.isMinimized = false,
    this.isMaximized = false,
    this.isClosed = false,
  });
}

class WindowManager extends ChangeNotifier {
  final List<ZionWindow> _windows = [];
  String? _activeWindowId;
  int _zOrderCounter = 0;

  List<ZionWindow> get windows => _windows.where((w) => !w.isClosed && !w.isMinimized).toList();
  List<ZionWindow> get minimizedWindows => _windows.where((w) => w.isMinimized && !w.isClosed).toList();
  String? get activeWindowId => _activeWindowId;

  String open(String title, Widget content, {double width = 600, double height = 400}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final window = ZionWindow(id: id, title: title, content: content, width: width, height: height);
    _windows.add(window);
    _activeWindowId = id;
    notifyListeners();
    return id;
  }

  void close(String id) {
    final window = _windows.firstWhere((w) => w.id == id, orElse: () => ZionWindow(id: '', title: '', content: const SizedBox()));
    window.isClosed = true;
    if (_activeWindowId == id) _activeWindowId = _windows.where((w) => !w.isClosed).isNotEmpty ? _windows.where((w) => !w.isClosed).last.id : null;
    notifyListeners();
  }

  void minimize(String id) {
    final window = _windows.firstWhere((w) => w.id == id);
    window.isMinimized = !window.isMinimized;
    if (_activeWindowId == id) _activeWindowId = _windows.where((w) => !w.isClosed && !w.isMinimized).isNotEmpty ? _windows.where((w) => !w.isClosed && !w.isMinimized).last.id : null;
    notifyListeners();
  }

  void maximize(String id) {
    final window = _windows.firstWhere((w) => w.id == id);
    window.isMaximized = !window.isMaximized;
    notifyListeners();
  }

  void setActive(String id) {
    _activeWindowId = id;
    notifyListeners();
  }

  void updatePosition(String id, double dx, double dy) {
    final window = _windows.firstWhere((w) => w.id == id);
    window.x += dx;
    window.y += dy;
    notifyListeners();
  }

  void updateSize(String id, double dw, double dh) {
    final window = _windows.firstWhere((w) => w.id == id);
    window.width += dw;
    window.height += dh;
    notifyListeners();
  }
}
