import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ZionSession {
  ZionSession({required this.id, required this.name, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  final String id;
  String name;
  final DateTime createdAt;
  DateTime lastActive = DateTime.now();
  final List<String> commands = <String>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'lastActive': lastActive.toIso8601String(),
        'commands': commands,
      };

  static ZionSession fromJson(Map<String, dynamic> json) {
    final session = ZionSession(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Session',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
    session.lastActive = DateTime.tryParse(json['lastActive'] as String? ?? '') ?? session.createdAt;
    session.commands.addAll((json['commands'] as List<dynamic>? ?? const <dynamic>[]).cast<String>());
    return session;
  }
}

class SessionManager {
  static const _key = 'zion.runtime.sessions.v1';
  final Map<String, ZionSession> _sessions = <String, ZionSession>{};
  String? _activeId;

  List<ZionSession> get sessions => List.unmodifiable(_sessions.values);
  ZionSession? get active => _activeId == null ? null : _sessions[_activeId];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List<dynamic>?) ?? const <dynamic>[];
    for (final item in list) {
      final session = ZionSession.fromJson((item as Map).cast<String, dynamic>());
      _sessions[session.id] = session;
    }
    if (_sessions.isNotEmpty) _activeId = _sessions.values.last.id;
  }

  Future<ZionSession> create([String name = 'Session']) async {
    final id = 's-${DateTime.now().microsecondsSinceEpoch}';
    final session = ZionSession(id: id, name: name);
    _sessions[id] = session;
    _activeId = id;
    await save();
    return session;
  }

  Future<void> activate(String id) async {
    if (!_sessions.containsKey(id)) throw StateError('Unknown session: $id');
    _activeId = id;
    _sessions[id]!.lastActive = DateTime.now();
    await save();
  }

  Future<void> recordCommand(String command) async {
    final session = active ?? await create();
    session.commands.add(command);
    session.lastActive = DateTime.now();
    if (session.commands.length > 500) session.commands.removeAt(0);
    await save();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_sessions.values.map((e) => e.toJson()).toList()));
  }
}

class RuntimeStatistics {
  int commands = 0;
  int successful = 0;
  int failed = 0;
  int blocked = 0;
  int unavailable = 0;
  Duration totalDuration = Duration.zero;

  double get successRate => commands == 0 ? 0 : successful / commands;
  Map<String, dynamic> toJson() => {
        'commands': commands,
        'successful': successful,
        'failed': failed,
        'blocked': blocked,
        'unavailable': unavailable,
        'successRate': successRate,
        'totalDurationMs': totalDuration.inMilliseconds,
      };
}

class StatisticsEngine {
  final RuntimeStatistics statistics = RuntimeStatistics();
  void record({required String outcome, required Duration duration}) {
    statistics.commands++;
    statistics.totalDuration += duration;
    switch (outcome.toUpperCase()) {
      case 'SUCCESS': statistics.successful++; break;
      case 'BLOCKED': statistics.blocked++; break;
      case 'UNAVAILABLE': statistics.unavailable++; break;
      default: statistics.failed++;
    }
  }
}

class CommandEngine {
  CommandEngine({SessionManager? sessions, StatisticsEngine? statistics})
      : sessions = sessions ?? SessionManager(),
        statistics = statistics ?? StatisticsEngine();
  final SessionManager sessions;
  final StatisticsEngine statistics;
  final StreamController<Map<String, dynamic>> _events = StreamController.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<Map<String, dynamic>> record(String command, Future<Map<String, dynamic>> Function() executor) async {
    final started = DateTime.now();
    await sessions.recordCommand(command);
    try {
      final result = await executor();
      final outcome = (result['status'] ?? 'FAILED').toString();
      statistics.record(outcome: outcome, duration: DateTime.now().difference(started));
      final event = {...result, 'command': command, 'durationMs': DateTime.now().difference(started).inMilliseconds};
      _events.add(event);
      return event;
    } catch (error) {
      statistics.record(outcome: 'FAILED', duration: DateTime.now().difference(started));
      final event = <String, dynamic>{'status': 'FAILED', 'command': command, 'error': '$error'};
      _events.add(event);
      return event;
    }
  }

  Future<void> dispose() => _events.close();
}
