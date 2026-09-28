import 'package:flutter/material.dart';
import 'floating_window.dart';

class FloatingWindowManager extends StatefulWidget {
  final Widget child;
  const FloatingWindowManager({super.key, required this.child});

  @override
  State<FloatingWindowManager> createState() => FloatingWindowManagerState();
}

class FloatingWindowManagerState extends State<FloatingWindowManager> {
  final List<FloatingWindowInstance> _windows = [];
  int _nextId = 0;

  void openWindow(String title, Widget content, {Size? size, Offset? position}) {
    setState(() {
      _windows.add(FloatingWindowInstance(id: _nextId++, title: title, content: content, size: size, position: position));
    });
  }

  void closeWindow(int id) {
    setState(() => _windows.removeWhere((w) => w.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._windows.map((w) => FloatingWindow(
          key: ValueKey(w.id),
          title: w.title,
          child: w.content,
          onClose: () => closeWindow(w.id),
          windowId: w.id,
          initialSize: w.size ?? const Size(350, 500),
          initialPosition: w.position ?? Offset(100 + w.id * 20, 100 + w.id * 20),
        )),
      ],
    );
  }
}

class FloatingWindowInstance {
  final int id;
  final String title;
  final Widget content;
  final Size? size;
  final Offset? position;
  FloatingWindowInstance({required this.id, required this.title, required this.content, this.size, this.position});
}
