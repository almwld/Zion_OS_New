import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';

class CommandPrediction {
  final String command;
  final double confidence;
  final String reason;
  const CommandPrediction({required this.command, required this.confidence, required this.reason});
}

/// Local next-command predictor. History is stored only in app-private
/// preferences; predictions are suggestions and are never executed.
class CommandPredictor {
  final Map<String, Map<String, int>> _transitions = {};
  final Map<String, int> _frequency = {};
  final Queue<String> _recent = Queue<String>();
  final int maxHistory;
  bool _loaded = false;

  CommandPredictor({this.maxHistory = 100});

  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('zion_terminal_history') ?? const <String>[];
      for (final command in history.take(maxHistory)) _trainMemory(command);
    } catch (_) {}
  }

  Future<void> train(String command) async {
    _trainMemory(command);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('zion_terminal_history', _recent.toList());
    } catch (_) {}
  }

  void _trainMemory(String command) {
    final value = command.trim();
    if (value.isEmpty) return;
    _frequency[value] = (_frequency[value] ?? 0) + 1;
    if (_recent.isNotEmpty) {
      final next = _transitions.putIfAbsent(_recent.last, () => <String, int>{});
      next[value] = (next[value] ?? 0) + 1;
    }
    _recent.add(value);
    while (_recent.length > maxHistory) _recent.removeFirst();
  }

  List<CommandPrediction> predictNext(String currentCommand) {
    final candidates = <String, double>{};
    final reasons = <String, String>{};
    final transitions = _transitions[currentCommand.trim()];
    if (transitions != null && transitions.isNotEmpty) {
      final total = transitions.values.fold<int>(0, (a, b) => a + b);
      for (final entry in transitions.entries) { candidates[entry.key] = entry.value / total; reasons[entry.key] = 'نمط انتقال محلي'; }
    }
    final total = _frequency.values.fold<int>(0, (a, b) => a + b);
    if (total > 0) for (final entry in _frequency.entries) {
      if (entry.key == currentCommand.trim()) continue;
      candidates.putIfAbsent(entry.key, () => entry.value / total);
      reasons.putIfAbsent(entry.key, () => 'تكرار محلي');
    }
    final result = candidates.entries.map((e) => CommandPrediction(command: e.key, confidence: e.value.clamp(0.0, 1.0), reason: reasons[e.key]!)).toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return result.take(5).toList();
  }

  List<String> autocomplete(String partial) {
    final value = partial.trim().toLowerCase();
    return _frequency.keys.where((c) => c.toLowerCase().startsWith(value)).take(10).toList();
  }

  Future<void> clear() async {
    _transitions.clear(); _frequency.clear(); _recent.clear();
    try { await (await SharedPreferences.getInstance()).remove('zion_terminal_history'); } catch (_) {}
  }
}
