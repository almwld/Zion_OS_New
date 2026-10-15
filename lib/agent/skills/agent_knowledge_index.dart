import 'dart:convert';
import 'package:flutter/services.dart';

/// Offline, searchable operational knowledge for Zion's local agent.
/// Entries are references, not executable commands or permission grants.
class AgentKnowledgeEntry {
  const AgentKnowledgeEntry({required this.id, required this.title, required this.domain, required this.keywords, required this.summary, required this.commands, required this.limits});
  final String id, title, domain, summary, limits;
  final List<String> keywords, commands;
  factory AgentKnowledgeEntry.fromJson(Map<String, dynamic> json) => AgentKnowledgeEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    domain: json['domain'] as String,
    keywords: (json['keywords'] as List? ?? const []).whereType<String>().toList(growable: false),
    summary: json['summary'] as String? ?? '',
    commands: (json['commands'] as List? ?? const []).whereType<String>().toList(growable: false),
    limits: json['limits'] as String? ?? '',
  );
}

class AgentKnowledgeIndex {
  AgentKnowledgeIndex({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  static const String assetPath = 'assets/agent_skills/knowledge_index.json';
  List<AgentKnowledgeEntry>? _cache;

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<List<AgentKnowledgeEntry>> entries() async {
    final cached = _cache;
    if (cached != null) return cached;
    final decoded = jsonDecode(await _bundle.loadString(assetPath));
    if (decoded is! Map || decoded['entries'] is! List) {
      throw const FormatException('Invalid Zion agent knowledge index format.');
    }
    final loaded = (decoded['entries'] as List)
        .whereType<Map>()
        .map((entry) => AgentKnowledgeEntry.fromJson(Map<String, dynamic>.from(entry)))
        .toList(growable: false);
    if (loaded.any((entry) => entry.id.trim().isEmpty || entry.title.trim().isEmpty || entry.domain.trim().isEmpty)) {
      throw const FormatException('Knowledge index entries require non-empty id, title, and domain.');
    }
    final ids = loaded.map((entry) => entry.id).toSet();
    if (ids.length != loaded.length) throw const FormatException('Duplicate knowledge index entry id.');
    _cache = loaded;
    return loaded;
  }

  Future<List<AgentKnowledgeEntry>> rank(String task, {int limit = 5}) async {
    if (task.trim().isEmpty || limit < 1) return const [];
    final normalized = _normalize(task);
    final loaded = await entries();
    final scored = loaded.map((entry) {
      var score = 0;
      for (final keyword in entry.keywords) {
        final normalizedKeyword = _normalize(keyword.trim());
        if (normalizedKeyword.isNotEmpty && normalized.contains(normalizedKeyword)) {
          score += normalizedKeyword.contains(' ') ? 5 : 3;
        }
      }
      for (final word in _normalize('${entry.title} ${entry.domain}')
          .split(RegExp(r'[^a-z0-9\u0600-\u06FF]+'))) {
        if (word.length > 3 && normalized.contains(word)) score++;
      }
      return (entry: entry, score: score);
    }).where((item) => item.score > 0).toList()
      ..sort((a, b) {
        final scoreOrder = b.score.compareTo(a.score);
        return scoreOrder != 0 ? scoreOrder : loaded.indexOf(a.entry).compareTo(loaded.indexOf(b.entry));
      });
    return scored.take(limit).map((item) => item.entry).toList(growable: false);
  }

  Future<String> contextFor(String task, {int maxEntries = 3, int maxTotalChars = 900}) async {
    if (task.trim().isEmpty || maxEntries < 1 || maxTotalChars < 1) return '';
    final ranked = await rank(task, limit: maxEntries);
    if (ranked.isEmpty) return '';
    const header = 'Relevant Zion local knowledge (reference only; verify with live tool output):\n';
    if (maxTotalChars <= 0) return '';
    final out = StringBuffer(
      header.length > maxTotalChars ? header.substring(0, maxTotalChars) : header,
    );
    if (header.length >= maxTotalChars) return out.toString();
    for (final entry in ranked) {
      final commandText = entry.commands.isEmpty ? '' : '\nExamples: ${entry.commands.join(' ; ')}';
      final section = '\n- [${entry.domain}] ${entry.title}: ${entry.summary}${commandText}\nLimit: ${entry.limits}\n';
      final remaining = maxTotalChars - out.length;
      if (remaining <= 0) break;
      if (section.length > remaining) {
        // Keep a useful bounded excerpt even when one complete entry is larger
        // than the caller's budget; never return only a header for a relevant task.
        out.write(section.substring(0, remaining));
        break;
      }
      out.write(section);
    }
    return out.toString();
  }
}
