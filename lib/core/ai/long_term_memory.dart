import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AIMemoryEntry {
  final String id;
  final String kind;
  final String text;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const AIMemoryEntry({
    required this.id,
    required this.kind,
    required this.text,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory AIMemoryEntry.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'];
    return AIMemoryEntry(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'event',
      text: json['text']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      metadata: meta is Map
          ? Map<String, dynamic>.from(meta)
          : const <String, dynamic>{},
    );
  }
}

/// Persistent memory for local agents. Entries are bounded before writing so
/// one verbose tool response cannot balloon SharedPreferences or stall startup.
class LongTermAIMemory {
  static const _key = 'zion_ai_long_term_memory_v1';
  static const int maxEntries = 2500;
  static const int maxTextChars = 3000;
  static const int maxMetadataChars = 1200;

  final List<AIMemoryEntry> _entries = <AIMemoryEntry>[];
  bool _loaded = false;
  Future<void> _saveQueue = Future<void>.value();

  List<AIMemoryEntry> get entries => List<AIMemoryEntry>.unmodifiable(_entries);

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? const <String>[];
      final decoded = <AIMemoryEntry>[];
      for (final item in raw) {
        try {
          final json = jsonDecode(item);
          if (json is Map) {
            decoded.add(AIMemoryEntry.fromJson(Map<String, dynamic>.from(json)));
          }
        } catch (_) {
          // Skip one corrupt record without discarding all recoverable memory.
        }
      }
      _entries
        ..clear()
        ..addAll(decoded.length > maxEntries
            ? decoded.sublist(decoded.length - maxEntries)
            : decoded);
    } catch (_) {
      // Platform storage can be unavailable in pure Dart/widget-test hosts.
      _entries.clear();
    }
    _loaded = true;
  }

  Future<void> remember({
    required String kind,
    required String text,
    Map<String, dynamic> metadata = const {},
  }) async {
    await load();
    final cleanKind = kind.trim().isEmpty ? 'event' : kind.trim();
    final cleanText = _truncate(text.trim(), maxTextChars);
    if (cleanText.isEmpty) return;

    final boundedMetadata = _boundMetadata(metadata);
    // Avoid repeatedly storing the exact same tool response during retries.
    final duplicateIndex = _entries.lastIndexWhere((entry) =>
        entry.kind == cleanKind &&
        entry.text == cleanText &&
        entry.metadata['tool'] == boundedMetadata['tool'] &&
        entry.metadata['success'] == boundedMetadata['success']);
    if (duplicateIndex >= 0 &&
        DateTime.now().difference(_entries[duplicateIndex].timestamp) <
            const Duration(seconds: 8)) {
      return;
    }

    _entries.add(AIMemoryEntry(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      kind: cleanKind,
      text: cleanText,
      timestamp: DateTime.now(),
      metadata: boundedMetadata,
    ));
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    await _save();
  }

  List<AIMemoryEntry> search(String query, {int limit = 20}) {
    final safeLimit = limit.clamp(1, 100).toInt();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return _entries.reversed.take(safeLimit).toList(growable: false);
    }
    final terms = q.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final scored = <({AIMemoryEntry entry, int score, DateTime timestamp})>[];
    for (final entry in _entries) {
      final hay = '${entry.kind} ${entry.text} ${jsonEncode(entry.metadata)}'
          .toLowerCase();
      final score = terms.where(hay.contains).length;
      if (score > 0) {
        scored.add((entry: entry, score: score, timestamp: entry.timestamp));
      }
    }
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : b.timestamp.compareTo(a.timestamp);
    });
    return scored
        .take(safeLimit)
        .map((item) => item.entry)
        .toList(growable: false);
  }

  Future<void> clear() async {
    _entries.clear();
    await _save();
  }

  Map<String, dynamic> _boundMetadata(Map<String, dynamic> metadata) {
    try {
      if (jsonEncode(metadata).length <= maxMetadataChars) {
        return Map<String, dynamic>.from(metadata);
      }
    } catch (_) {
      // Fall through and retain only scalar, serializable metadata.
    }
    final bounded = <String, dynamic>{};
    for (final entry in metadata.entries.take(12)) {
      final value = entry.value;
      if (value == null || value is bool || value is num) {
        bounded[entry.key] = value;
      } else if (value is String) {
        bounded[entry.key] = _truncate(value, 240);
      } else {
        bounded[entry.key] = _truncate(value.toString(), 240);
      }
      try {
        if (jsonEncode(bounded).length > maxMetadataChars) {
          bounded.remove(entry.key);
          break;
        }
      } catch (_) {
        bounded.remove(entry.key);
      }
    }
    return bounded;
  }

  String _truncate(String value, int maxChars) =>
      value.length <= maxChars ? value : '${value.substring(0, maxChars)}…';

  Future<void> _save() {
    // Serialize writes so simultaneous agent steps cannot race persistence.
    _saveQueue = _saveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _key,
          _entries.map((entry) => jsonEncode(entry.toJson())).toList(),
        );
      } catch (_) {
        // Persistence is best-effort; storage failure must not fail agent work.
      }
    });
    return _saveQueue;
  }
}
