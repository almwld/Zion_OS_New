import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'floating_window.dart';

class FloatingWindowSnapshot {
  const FloatingWindowSnapshot({required this.appKey, required this.title, required this.width, required this.height, required this.left, required this.top, required this.workspace});
  final String appKey;
  final String title;
  final double width;
  final double height;
  final double left;
  final double top;
  final int workspace;

  Map<String, dynamic> toJson() => {'appKey': appKey, 'title': title, 'width': width, 'height': height, 'left': left, 'top': top, 'workspace': workspace};

  static FloatingWindowSnapshot? fromJson(dynamic value) {
    if (value is! Map) return null;
    final map = value.cast<String, dynamic>();
    final appKey = map['appKey'];
    final title = map['title'];
    if (appKey is! String || title is! String) return null;
    return FloatingWindowSnapshot(
      appKey: appKey,
      title: title,
      width: (map['width'] as num?)?.toDouble() ?? 350,
      height: (map['height'] as num?)?.toDouble() ?? 500,
      left: (map['left'] as num?)?.toDouble() ?? 100,
      top: (map['top'] as num?)?.toDouble() ?? 100,
      workspace: (map['workspace'] as num?)?.toInt() ?? 0,
    );
  }
}

class FloatingWindowManager extends StatefulWidget {
  final Widget child;
  const FloatingWindowManager({super.key, required this.child});
  @override
  State<FloatingWindowManager> createState() => FloatingWindowManagerState();
}

class FloatingWindowManagerState extends State<FloatingWindowManager> {
  static const _storageKey = 'zion.desktop.floating_windows.v2';
  static const int workspaceCount = 4;
  int _activeWorkspace = 0;
  int get activeWorkspace => _activeWorkspace;
  void switchWorkspace(int workspace) { if (workspace < 0 || workspace >= workspaceCount || workspace == _activeWorkspace) return; setState(() => _activeWorkspace = workspace); _saveSnapshots(); }
  final List<FloatingWindowInstance> _windows = [];
  int _nextId = 0;
  bool _restoring = false;

  Future<List<FloatingWindowSnapshot>> loadSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.map(FloatingWindowSnapshot.fromJson).whereType<FloatingWindowSnapshot>().take(12).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  void openWindow(String title, Widget content, {String? appKey, Size? size, Offset? position}) {
    setState(() {
      _windows.add(FloatingWindowInstance(
        id: _nextId++,
        title: title,
        content: content,
        appKey: appKey ?? title,
        workspace: _activeWorkspace,
        size: size,
        position: position,
      ));
    });
    _saveSnapshots();
  }

  void restoreWindow(String title, Widget content, {required String appKey, Size? size, Offset? position, int? workspace}) {
    setState(() {
      _windows.add(FloatingWindowInstance(
        id: _nextId++,
        title: title,
        content: content,
        appKey: appKey,
        workspace: _activeWorkspace,
        size: size,
        position: position,
      ));
    });
  }

  Future<void> restoreSnapshots(List<FloatingWindowSnapshot> snapshots, Widget? Function(String appKey) contentFactory) async {
    if (_restoring || snapshots.isEmpty) return;
    _restoring = true;
    for (final snapshot in snapshots) {
      final content = contentFactory(snapshot.appKey);
      if (content == null) continue;
      restoreWindow(snapshot.title, content, appKey: snapshot.appKey, size: Size(snapshot.width, snapshot.height), position: Offset(snapshot.left, snapshot.top), workspace: snapshot.workspace);
    }
    _restoring = false;
  }

  void closeWindow(int id) {
    setState(() => _windows.removeWhere((w) => w.id == id));
    _saveSnapshots();
  }

  void _saveSnapshots() {
    if (_restoring) return;
    final snapshots = _windows.map((w) => FloatingWindowSnapshot(
      appKey: w.appKey,
      title: w.title,
      width: w.size?.width ?? 350,
      height: w.size?.height ?? 500,
      left: w.position?.dx ?? 100,
      top: w.position?.dy ?? 100,
      workspace: w.workspace,
    )).map((e) => e.toJson()).toList();
    SharedPreferences.getInstance().then((prefs) => prefs.setString(_storageKey, jsonEncode(snapshots)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(top: 10, left: 0, right: 0, child: Center(child: Material(color: Colors.transparent, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black.withOpacity(.55), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)), child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(workspaceCount, (i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: ChoiceChip(label: Text('W${i + 1}'), selected: _activeWorkspace == i, onSelected: (_) => switchWorkspace(i))))))))),
        ..._windows.where((w) => w.workspace == _activeWorkspace).map((w) => FloatingWindow(
          key: ValueKey(w.id),
          title: w.title,
          child: w.content,
          onClose: () => closeWindow(w.id),
          onChanged: (size, position) {
              w.size = size;
              w.position = position;
              _saveSnapshots();
            },
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
  final String appKey;
  final int workspace;
  Size? size;
  Offset? position;
  FloatingWindowInstance({required this.id, required this.title, required this.content, required this.appKey, required this.workspace, this.size, this.position});
}
