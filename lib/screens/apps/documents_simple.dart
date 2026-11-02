import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Real document browser. It lists files found on the device instead of
/// presenting bundled sample records.
class DocumentsApp extends StatefulWidget {
  const DocumentsApp({super.key});

  @override
  State<DocumentsApp> createState() => _DocumentsAppState();
}

class _DocumentsAppState extends State<DocumentsApp> {
  static const _accent = Color(0xFF38BDF8);
  static const _background = Color(0xFF0B1220);
  static const _extensions = <String>{
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'txt', 'rtf', 'csv', 'md', 'odt', 'ods', 'odp',
  };

  final List<File> _files = <File>[];
  bool _loading = true;
  bool _permissionDenied = false;
  String? _error;
  String _query = '';
  String _selectedType = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _permissionDenied = false;
    });
    try {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _permissionDenied = true;
          _files.clear();
        });
        return;
      }

      final roots = <Directory>[
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Documents'),
        Directory('/storage/emulated/0'),
      ];
      final found = <String, File>{};
      for (final root in roots) {
        if (!await root.exists()) continue;
        try {
          await for (final entity in root.list(recursive: true, followLinks: false)) {
            if (entity is! File) continue;
            final name = entity.path.split('/').last;
            if (name.startsWith('.')) continue;
            final extension = _extension(name);
            if (_extensions.contains(extension)) found[entity.path] = entity;
            if (found.length >= 1500) break;
          }
        } on FileSystemException {
          // A restricted folder should not prevent scanning other locations.
        }
        if (found.length >= 1500) break;
      }
      final files = found.values.toList()
        ..sort((a, b) => a.path.split('/').last.toLowerCase()
            .compareTo(b.path.split('/').last.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _files
          ..clear()
          ..addAll(files);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر قراءة المستندات: $error';
      });
    }
  }

  String _extension(String name) {
    final index = name.lastIndexOf('.');
    return index < 0 ? '' : name.substring(index + 1).toLowerCase();
  }

  String _typeLabel(String extension) {
    if (extension == 'pdf') return 'PDF';
    if (const {'doc', 'docx', 'odt', 'rtf'}.contains(extension)) return 'Word';
    if (const {'xls', 'xlsx', 'ods', 'csv'}.contains(extension)) return 'جداول';
    if (const {'ppt', 'pptx', 'odp'}.contains(extension)) return 'عروض';
    return 'نصوص';
  }

  Color _typeColor(String extension) {
    switch (_typeLabel(extension)) {
      case 'PDF': return const Color(0xFFF87171);
      case 'Word': return const Color(0xFF60A5FA);
      case 'جداول': return const Color(0xFF34D399);
      case 'عروض': return const Color(0xFFFBBF24);
      default: return _accent;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  List<File> get _filteredFiles {
    return _files.where((file) {
      final name = file.path.split('/').last;
      final extension = _extension(name);
      final matchesQuery = name.toLowerCase().contains(_query.toLowerCase());
      final matchesType = _selectedType == 'الكل' ||
          _typeLabel(extension) == _selectedType;
      return matchesQuery && matchesType;
    }).toList();
  }

  Future<void> _shareFile(File file) async {
    try {
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: file.path.split('/').last,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّرت مشاركة الملف: $error')),
      );
    }
  }

  Future<void> _showDetails(File file) async {
    final stat = await file.stat();
    if (!mounted) return;
    final name = file.path.split('/').last;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111C2B),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _detail('المسار', file.path),
              _detail('الحجم', _formatSize(stat.size)),
              _detail('آخر تعديل', stat.modified.toLocal().toString()),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _shareFile(file);
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('مشاركة / فتح باستخدام تطبيق آخر'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      SizedBox(width: 82, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final files = _filteredFiles;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('المستندات'),
        actions: <Widget>[
          IconButton(
            tooltip: 'إعادة الفحص',
            onPressed: _loading ? null : _loadDocuments,
            icon: const Icon(Icons.refresh_rounded, color: _accent),
          ),
        ],
      ),
      body: Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن مستند بالاسم...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: _accent),
              filled: true,
              fillColor: const Color(0xFF111C2B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: <String>['الكل', 'PDF', 'Word', 'جداول', 'عروض', 'نصوص'].map((type) {
              final selected = _selectedType == type;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedType = type),
                  selectedColor: _accent.withOpacity(0.2),
                  labelStyle: TextStyle(color: selected ? _accent : Colors.white70),
                  side: BorderSide(color: selected ? _accent : Colors.white12),
                  backgroundColor: const Color(0xFF111C2B),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _permissionDenied
                  ? _stateView(
                      icon: Icons.folder_off_outlined,
                      title: 'يلزم إذن الوصول إلى الملفات',
                      message: 'اسمح بالوصول إلى الملفات كي يتمكن Zion من فهرسة المستندات الموجودة على الجهاز.',
                      action: 'فتح الإعدادات',
                      onAction: openAppSettings,
                    )
                  : _error != null
                      ? _stateView(icon: Icons.error_outline, title: 'تعذّر تحميل المستندات', message: _error!, action: 'إعادة المحاولة', onAction: _loadDocuments)
                      : files.isEmpty
                          ? _stateView(
                              icon: Icons.description_outlined,
                              title: _files.isEmpty ? 'لا توجد مستندات مدعومة' : 'لا توجد نتائج مطابقة',
                              message: _files.isEmpty ? 'سيتم عرض ملفات PDF وWord وExcel وPowerPoint والنصوص الموجودة في الجهاز هنا.' : 'جرّب تغيير عبارة البحث أو نوع الملف.',
                              action: _files.isEmpty ? 'إعادة الفحص' : null,
                              onAction: _loadDocuments,
                            )
                          : RefreshIndicator(
                              color: _accent,
                              onRefresh: _loadDocuments,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                                itemCount: files.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final file = files[index];
                                  final name = file.path.split('/').last;
                                  final extension = _extension(name);
                                  final color = _typeColor(extension);
                                  return Material(
                                    color: const Color(0xFF111C2B),
                                    borderRadius: BorderRadius.circular(15),
                                    child: ListTile(
                                      onTap: () => _showDetails(file),
                                      leading: Container(
                                        width: 44,
                                        height: 48,
                                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                                        child: Icon(Icons.insert_drive_file_outlined, color: color),
                                      ),
                                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      subtitle: Text('${_typeLabel(extension)} • ${file.parent.path}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                      trailing: IconButton(
                                        tooltip: 'مشاركة الملف',
                                        onPressed: () => _shareFile(file),
                                        icon: const Icon(Icons.share_outlined, color: _accent),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
        ),
      ]),
    );
  }

  Widget _stateView({
    required IconData icon,
    required String title,
    required String message,
    String? action,
    VoidCallback? onAction,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(icon, size: 58, color: _accent.withOpacity(0.65)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: Colors.white54, height: 1.5), textAlign: TextAlign.center),
        if (action != null && onAction != null) ...<Widget>[
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.refresh), label: Text(action)),
        ],
      ]),
    ),
  );
}
