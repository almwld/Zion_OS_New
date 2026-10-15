import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ObsidianVaultScreen extends StatefulWidget {
  const ObsidianVaultScreen({super.key, required this.initialMarkdown});
  final String initialMarkdown;

  @override
  State<ObsidianVaultScreen> createState() => _ObsidianVaultScreenState();
}

class _ObsidianVaultScreenState extends State<ObsidianVaultScreen> {
  final _title = TextEditingController(text: 'Zion Super Agent Session');
  final _tags = TextEditingController(text: 'zion, super-agent, ai');
  final _content = TextEditingController();
  List<File> _notes = const [];
  bool _saving = false;
  String? _vaultPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _content.text = widget.initialMarkdown;
    _refreshNotes();
  }

  Future<Directory> _vault() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/Obsidian/Zion Super Agent');
    await dir.create(recursive: true);
    _vaultPath = dir.path;
    return dir;
  }

  String _slug(String value) {
    final clean = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    return clean.isEmpty ? 'zion-note' : clean.substring(0, clean.length > 70 ? 70 : clean.length);
  }

  String _yaml(String value) => value.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', ' ');

  String _markdown() {
    final title = _title.text.trim().isEmpty ? 'Zion Agent Note' : _title.text.trim();
    final tags = _tags.text.split(',').map((t) => t.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-\u0600-\u06FF]'), '')).where((t) => t.isNotEmpty).toSet();
    final date = DateTime.now().toIso8601String();
    return '---\ntitle: "${_yaml(title)}"\ncreated: "$date"\ntags: [${tags.map((t) => '"${_yaml(t)}"').join(', ')}]\nsource: Zion Super Agent\n---\n\n# $title\n\n${_content.text.trim()}\n\n---\n*Created locally by Zion OS · [[Zion Super Agent]]*\n';
  }

  Future<void> _refreshNotes() async {
    try {
      final dir = await _vault();
      final files = await dir.list().where((e) => e is File && e.path.endsWith('.md')).cast<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      if (mounted) setState(() { _notes = files; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر فتح الخزنة المحلية: $e');
    }
  }

  Future<void> _saveNote({bool share = false}) async {
    if (_saving) return;
    setState(() { _saving = true; _error = null; });
    try {
      final dir = await _vault();
      final now = DateTime.now();
      final filename = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${_slug(_title.text)}.md';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(_markdown(), flush: true);
      await _refreshNotes();
      if (share) {
        await Share.shareXFiles([XFile(file.path)], text: 'ملاحظة Markdown متوافقة مع Obsidian من Zion OS', subject: _title.text.trim());
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(share ? 'حُفظت الملاحظة وفتح نظام المشاركة لإرسالها إلى Obsidian' : 'حُفظت الملاحظة في الخزنة المحلية')));
    } catch (e) {
      if (mounted) setState(() => _error = 'فشل حفظ الملاحظة: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openNote(File file) async {
    try {
      _content.text = await file.readAsString();
      _title.text = file.uri.pathSegments.last.replaceAll('.md', '');
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذرت قراءة الملاحظة: $e');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _tags.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A1018);
    const panel = Color(0xFF121E29);
    const accent = Color(0xFF8D78FF);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('Obsidian · قاعدة المعرفة'), backgroundColor: const Color(0xFF0E1722)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFF35405B))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.hub_outlined, color: accent), SizedBox(width: 8), Expanded(child: Text('خزنة Markdown محلية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)))]),
          const SizedBox(height: 6),
          const Text('ملاحظات متوافقة مع Obsidian: YAML frontmatter، وسوم، وروابط داخلية. تُحفظ محلياً ثم يمكن مشاركتها إلى تطبيق Obsidian أو مزامنتها بالطريقة التي تختارها.', style: TextStyle(color: Color(0xFF9BAFBE), height: 1.5, fontSize: 12)),
          if (_vaultPath != null) Padding(padding: const EdgeInsets.only(top: 8), child: SelectableText(_vaultPath!, style: const TextStyle(color: Color(0xFFB5A9FF), fontSize: 10))),
        ])),
        const SizedBox(height: 14),
        _field(_title, 'عنوان الملاحظة'),
        const SizedBox(height: 9),
        _field(_tags, 'وسوم مفصولة بفواصل'),
        const SizedBox(height: 9),
        TextField(controller: _content, minLines: 8, maxLines: 18, style: const TextStyle(color: Colors.white, height: 1.45), decoration: _decoration('محتوى Markdown')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _saving ? null : () => _saveNote(), icon: const Icon(Icons.save_outlined), label: const Text('حفظ محلي'))),
          const SizedBox(width: 9),
          Expanded(child: FilledButton.icon(onPressed: _saving ? null : () => _saveNote(share: true), icon: const Icon(Icons.share_outlined), label: const Text('حفظ ومشاركة'))),
        ]),
        if (_saving) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Color(0xFFFF8585)))),
        const SizedBox(height: 22),
        Row(children: [const Expanded(child: Text('ملاحظات الخزنة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))), IconButton(onPressed: _refreshNotes, icon: const Icon(Icons.refresh, color: Color(0xFF9BAFBE)))]),
        if (_notes.isEmpty) const Text('لا توجد ملاحظات محفوظة بعد.', style: TextStyle(color: Color(0xFF8197A7), fontSize: 12)),
        for (final file in _notes) Card(color: panel, child: ListTile(
          leading: const Icon(Icons.description_outlined, color: accent),
          title: Text(file.uri.pathSegments.last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
          subtitle: Text('${(file.lengthSync() / 1024).toStringAsFixed(1)} KB', style: const TextStyle(color: Color(0xFF8197A7), fontSize: 10)),
          onTap: () => _openNote(file),
          trailing: IconButton(tooltip: 'مشاركة الملاحظة', icon: const Icon(Icons.ios_share, color: Color(0xFFB5A9FF), size: 19), onPressed: () => Share.shareXFiles([XFile(file.path)], subject: file.uri.pathSegments.last)),
        )),
      ]),
    );
  }

  Widget _field(TextEditingController controller, String label) => TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: _decoration(label));
  InputDecoration _decoration(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF8197A7), fontSize: 12), filled: true, fillColor: const Color(0xFF09131D), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF294252))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF294252))));
}
