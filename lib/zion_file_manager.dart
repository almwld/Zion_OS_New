import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Real app-scoped file manager. It deliberately uses Android's app-private
/// storage so it works with modern scoped-storage rules without claiming
/// access to the whole device filesystem.
class ZionFileManager extends StatefulWidget {
  const ZionFileManager({super.key});

  @override
  State<ZionFileManager> createState() => _ZionFileManagerState();
}

class _ZionFileManagerState extends State<ZionFileManager> {
  Directory? _directory;
  List<FileSystemEntity> _entries = const [];
  final List<Directory> _history = [];
  int _historyIndex = -1;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openRoot();
  }

  Future<void> _openRoot() async {
    try {
      final root = await getApplicationDocumentsDirectory();
      _history
        ..clear()
        ..add(root);
      _historyIndex = 0;
      await _load(root);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'تعذر الوصول إلى مساحة التطبيق: $e';
      });
    }
  }

  Future<void> _load(Directory directory) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await directory.list(followLinks: false).toList();
      entries.sort((a, b) {
        final ad = a is Directory;
        final bd = b is Directory;
        if (ad != bd) return ad ? -1 : 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _directory = directory;
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر قراءة المجلد: $e';
      });
    }
  }

  Future<void> _openDirectory(Directory directory) async {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(directory);
    _historyIndex++;
    await _load(directory);
  }

  Future<void> _back() async {
    if (_historyIndex <= 0) return;
    _historyIndex--;
    await _load(_history[_historyIndex]);
  }

  Future<void> _forward() async {
    if (_historyIndex >= _history.length - 1) return;
    _historyIndex++;
    await _load(_history[_historyIndex]);
  }

  Future<void> _refresh() async {
    final directory = _directory;
    if (directory != null) await _load(directory);
  }

  String _displayName(FileSystemEntity entity) {
    final path = entity.path;
    final separator = path.lastIndexOf(Platform.pathSeparator);
    return separator >= 0 ? path.substring(separator + 1) : path;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<String> _entryDetails(FileSystemEntity entity) async {
    if (entity is Directory) return 'مجلد\n${entity.path}';
    if (entity is File) {
      final stat = await entity.stat();
      return 'ملف\nالحجم: ${_formatSize(stat.size)}\nالمسار: ${entity.path}';
    }
    return entity.path;
  }

  @override
  Widget build(BuildContext context) {
    final directory = _directory;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0E0A),
            border: Border(bottom: BorderSide(color: Color(0xFF1A3A1A))),
          ),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41), size: 18), onPressed: _back, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
              IconButton(icon: const Icon(Icons.arrow_forward, color: Color(0xFF00FF41), size: 18), onPressed: _forward, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
              IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF00FF41), size: 18), onPressed: _refresh, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
              const SizedBox(width: 8),
              Expanded(child: Text(directory?.path ?? 'جارٍ التحميل...', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace', fontSize: 11))),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!)))
              : _entries.isEmpty && !_loading
                  ? const Center(child: Text('المجلد فارغ'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(4),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final isFolder = entry is Directory;
                        return ListTile(
                          leading: Icon(isFolder ? Icons.folder : Icons.description, color: isFolder ? Colors.orange : const Color(0xFF00FF41), size: 20),
                          title: Text(_displayName(entry), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace', fontSize: 12)),
                          dense: true,
                          onTap: isFolder ? () => _openDirectory(entry) : () async {
                            final details = await _entryDetails(entry);
                            if (!mounted) return;
                            showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(_displayName(entry)), content: Text(details), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))]));
                          },
                        );
                      },
                    ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0E0A),
            border: Border(top: BorderSide(color: Color(0xFF1A3A1A))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_entries.length} عناصر', style: const TextStyle(color: Color(0xFF00FF41), fontSize: 10, fontFamily: 'monospace')),
              const Text('تخزين التطبيق', style: TextStyle(color: Color(0xFF00FF41), fontSize: 10, fontFamily: 'monospace')),
            ],
          ),
        ),
      ],
    );
  }
}
