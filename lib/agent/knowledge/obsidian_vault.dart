import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ObsidianNote {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ObsidianNote({
    required this.id, required this.title, required this.body,
    this.tags = const [], required this.createdAt, required this.updatedAt,
  });

  List<String> get links {
    final matches = RegExp(r'\[\[([^\]]+)\]\]').allMatches(body);
    return matches.map((m) => m.group(1)!.trim())
      .where((value) => value.isNotEmpty).toSet().toList(growable: false);
  }

  Map<String, Object?> toJson() => {
    'id': id, 'title': title, 'body': body, 'tags': tags,
    'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
  };

  factory ObsidianNote.fromJson(Map<String, dynamic> json) => ObsidianNote(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? 'ملاحظة بلا عنوان',
    body: json['body']?.toString() ?? '',
    tags: (json['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

class ObsidianGraph {
  final List<ObsidianNote> notes;
  final Map<String, List<String>> edges;
  const ObsidianGraph({required this.notes, required this.edges});

  int get edgeCount => edges.values.fold<int>(0, (sum, value) => sum + value.length);
}

/// Local-first Markdown vault inspired by linked-note workflows.
/// Data stays in app-private SharedPreferences; no account or cloud is required.
class ObsidianVault {
  static const String _key = 'zion_obsidian_vault_v1';
  Future<List<ObsidianNote>> allNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map((e) =>
        ObsidianNote.fromJson(Map<String, dynamic>.from(e))).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return const [];
    }
  }

  Future<ObsidianNote> save({
    String? id, required String title, required String body,
    List<String> tags = const [],
  }) async {
    final notes = (await allNotes()).toList();
    final now = DateTime.now();
    final normalizedTitle = title.trim().isEmpty ? 'ملاحظة جديدة' : title.trim();
    final index = id == null ? -1 : notes.indexWhere((note) => note.id == id);
    final existing = index < 0 ? null : notes[index];
    final note = ObsidianNote(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      title: normalizedTitle,
      body: body,
      tags: tags.map((tag) => tag.trim().replaceFirst(RegExp(r'^#'), ''))
        .where((tag) => tag.isNotEmpty).toSet().toList(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (index < 0) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
    await _persist(notes);
    return note;
  }

  Future<void> delete(String id) async {
    final notes = (await allNotes()).where((note) => note.id != id).toList();
    await _persist(notes);
  }

  Future<List<ObsidianNote>> search(String query) async {
    final q = _normalize(query);
    if (q.isEmpty) return allNotes();
    final notes = await allNotes();
    return notes.where((note) => _normalize('${note.title}\n${note.body}\n${note.tags.join(' ')}').contains(q)).toList();
  }

  Future<ObsidianGraph> graph() async {
    final notes = await allNotes();
    final byTitle = <String, ObsidianNote>{for (final note in notes) _normalize(note.title): note};
    final edges = <String, List<String>>{};
    for (final note in notes) {
      final targets = <String>[];
      for (final link in note.links) {
        final target = byTitle[_normalize(link)];
        if (target != null && target.id != note.id) targets.add(target.id);
      }
      edges[note.id] = targets.toSet().toList();
    }
    return ObsidianGraph(notes: notes, edges: edges);
  }

  Future<String> contextFor(String query, {int maxNotes = 4, int maxChars = 6000}) async {
    final terms = _normalize(query).split(RegExp(r'[^a-z0-9\u0600-\u06FF]+')).where((term) => term.length > 2).toSet();
    if (terms.isEmpty) return '';
    final notes = await allNotes();
    final ranked = notes.map((note) {
      final haystack = _normalize(note.title + ' ' + note.body + ' ' + note.tags.join(' '));
      final score = terms.fold<int>(0, (sum, term) => sum + (haystack.contains(term) ? 1 : 0));
      return (note: note, score: score);
    }).where((item) => item.score > 0).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final out = StringBuffer('## Relevant local Obsidian notes\n');
    var added = 0;
    for (final item in ranked.take(maxNotes)) {
      final section = '\n### ' + item.note.title + '\n' + item.note.body + '\n';
      if (out.length + section.length > maxChars) break;
      out.write(section);
      added++;
    }
    return added == 0 ? '' : out.toString();
  }
  Future<String> exportMarkdown() async {
    final notes = await allNotes();
    return notes.map((note) {
      final tags = note.tags.map((tag) => '#$tag').join(' ');
      return '---\ntitle: "${note.title.replaceAll('"', '\\"')}"\ncreated: ${note.createdAt.toIso8601String()}\nupdated: ${note.updatedAt.toIso8601String()}\ntags: [$tags]\n---\n\n${note.body}';
    }).join('\n\n---\n\n');
  }

  Future<void> _persist(List<ObsidianNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(notes.map((note) => note.toJson()).toList()));
  }

  String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '').trim();
}
