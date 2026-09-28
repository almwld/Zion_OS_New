import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TerminalSession {
  TerminalSession({
    required this.id,
    required this.name,
    this.cwd = '',
    this.rows = 24,
    this.cols = 80,
  });

  final String id;
  String name;
  String cwd;
  int rows;
  int cols;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'cwd': cwd,
        'rows': rows,
        'cols': cols,
      };

  static TerminalSession fromJson(Map<String, dynamic> json) => TerminalSession(
        id: json['id'] as String,
        name: json['name'] as String,
        cwd: (json['cwd'] as String?) ?? '',
        rows: (json['rows'] as int?) ?? 24,
        cols: (json['cols'] as int?) ?? 80,
      );
}

/// Persistent local terminal session registry. It stores only metadata, never
/// passwords, private keys, or terminal output.
class TerminalSessionManager {
  static const _key = 'zion.terminal.sessions.v1';

  final Map<String, TerminalSession> _sessions = <String, TerminalSession>{};
  String? _activeId;

  List<TerminalSession> get sessions =>
      List<TerminalSession>.unmodifiable(_sessions.values);
  TerminalSession? get active =>
      _activeId == null ? null : _sessions[_activeId];

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _sessions
        ..clear()
        ..addEntries(
          decoded.whereType<Map>().map((item) {
            final s = TerminalSession.fromJson(
              Map<String, dynamic>.from(item),
            );
            return MapEntry<String, TerminalSession>(s.id, s);
          }),
        );
      if (_sessions.isNotEmpty) _activeId ??= _sessions.keys.first;
    } catch (_) {}
  }

  Future<TerminalSession> create({String? name}) async {
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    final session = TerminalSession(
      id: now,
      name: name?.trim().isNotEmpty == true ? name!.trim() : 'Terminal ' + (_sessions.length + 1).toString(),
    );
    _sessions[session.id] = session;
    _activeId = session.id;
    await _save();
    return session;
  }

  Future<bool> rename(String id, String name) async {
    final session = _sessions[id];
    final clean = name.trim();
    if (session == null || clean.isEmpty) return false;
    session.name = clean;
    await _save();
    return true;
  }

  Future<bool> activate(String id) async {
    if (!_sessions.containsKey(id)) return false;
    _activeId = id;
    await _save();
    return true;
  }

  Future<bool> updateGeometry(String id, {required int rows, required int cols}) async {
    final session = _sessions[id];
    if (session == null || rows < 1 || cols < 1) return false;
    session.rows = rows;
    session.cols = cols;
    await _save();
    return true;
  }

  Future<bool> updateCwd(String id, String cwd) async {
    final session = _sessions[id];
    if (session == null) return false;
    session.cwd = cwd;
    await _save();
    return true;
  }

  Future<bool> remove(String id) async {
    if (!_sessions.containsKey(id)) return false;
    _sessions.remove(id);
    if (_activeId == id) {
      _activeId = _sessions.isEmpty ? null : _sessions.keys.first;
    }
    await _save();
    return true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_sessions.values.map((s) => s.toJson()).toList()),
    );
  }
}
