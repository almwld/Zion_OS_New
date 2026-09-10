import 'dart:collection';

class CommandPrediction {
  final String command;
  final double confidence;
  final String reason;

  const CommandPrediction({
    required this.command,
    required this.confidence,
    required this.reason,
  });
}

/// Local, privacy-preserving next-command predictor based on user history.
/// Predictions are suggestions only and are never executed automatically.
class CommandPredictor {
  final Map<String, Map<String, int>> _transitions = {};
  final Map<String, int> _frequency = {};
  final Queue<String> _recent = Queue<String>();
  final int maxHistory;

  CommandPredictor({this.maxHistory = 100});

  void train(String command) {
    final value = command.trim();
    if (value.isEmpty) return;
    _frequency[value] = (_frequency[value] ?? 0) + 1;
    if (_recent.isNotEmpty) {
      final previous = _recent.last;
      final next = _transitions.putIfAbsent(previous, () => <String, int>{});
      next[value] = (next[value] ?? 0) + 1;
    }
    _recent.add(value);
    while (_recent.length > maxHistory) {
      _recent.removeFirst();
    }
  }

  List<CommandPrediction> predictNext(String currentCommand) {
    final candidates = <String, double>{};
    final reasons = <String, String>{};
    final transitions = _transitions[currentCommand.trim()];
    if (transitions != null && transitions.isNotEmpty) {
      final total = transitions.values.fold<int>(0, (a, b) => a + b);
      for (final entry in transitions.entries) {
        candidates[entry.key] = entry.value / total;
        reasons[entry.key] = 'نمط انتقال محلي';
      }
    }

    final totalFrequency = _frequency.values.fold<int>(0, (a, b) => a + b);
    if (totalFrequency > 0) {
      for (final entry in _frequency.entries) {
        if (entry.key == currentCommand.trim()) continue;
        candidates.putIfAbsent(entry.key, () => entry.value / totalFrequency);
        reasons.putIfAbsent(entry.key, () => 'تكرار محلي');
      }
    }

    final result = candidates.entries
        .map((e) => CommandPrediction(
              command: e.key,
              confidence: e.value.clamp(0.0, 1.0),
              reason: reasons[e.key]!,
            ))
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return result.take(5).toList();
  }

  List<String> autocomplete(String partial) {
    final value = partial.trim().toLowerCase();
    return _frequency.keys
        .where((command) => command.toLowerCase().startsWith(value))
        .take(10)
        .toList();
  }

  void clear() {
    _transitions.clear();
    _frequency.clear();
    _recent.clear();
  }
}
