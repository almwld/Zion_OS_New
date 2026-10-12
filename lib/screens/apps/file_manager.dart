import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FileManagerApp extends StatefulWidget {
  const FileManagerApp({super.key});

  @override
  State<FileManagerApp> createState() => _FileManagerAppState();
}

class _FileManagerAppState extends State<FileManagerApp> {
  String _currentPath = '/storage/emulated/0';
  List<FileSystemEntity> _items = <FileSystemEntity>[];
  bool _hasPermission = false;
  bool _checkingPermission = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (mounted) {
      setState(() {
        _checkingPermission = true;
        _error = null;
      });
    }

    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        // Android 11+ uses the special all-files access permission; the
        // legacy storage permission is insufficient on many modern devices.
        status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        if (!status.isGranted) {
          final legacy = await Permission.storage.status;
          status = legacy.isGranted ? legacy : await Permission.storage.request();
        }
      } else {
        status = await Permission.storage.request();
      }

      if (!mounted) return;
      setState(() {
        _hasPermission = status.isGranted;
        _checkingPermission = false;
        if (!status.isGranted) {
          _error = 'إذن الوصول إلى الملفات غير ممنوح. امنح الإذن ثم أعد المحاولة.';
        }
      });
      if (status.isGranted) await _loadItems();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checkingPermission = false;
        _hasPermission = false;
        _error = 'تعذر التحقق من إذن الملفات: $error';
      });
    }
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dir = Directory(_currentPath);
      if (!await dir.exists()) {
        if (!mounted) return;
        setState(() {
          _items = <FileSystemEntity>[];
          _loading = false;
          _error = 'المجلد غير موجود أو لا يمكن الوصول إليه: $_currentPath';
        });
        return;
      }

      final items = await dir.list(followLinks: false).toList();
      items.sort((a, b) => a.path.split('/').last.toLowerCase().compareTo(
            b.path.split('/').last.toLowerCase(),
          ));
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } on FileSystemException catch (error) {
      if (!mounted) return;
      setState(() {
        _items = <FileSystemEntity>[];
        _loading = false;
        _error = 'تعذر قراءة المجلد: ${error.message}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _items = <FileSystemEntity>[];
        _loading = false;
        _error = 'حدث خطأ أثناء تحميل الملفات: $error';
      });
    }
  }

  Future<void> _navigateTo(String path) async {
    if (!mounted) return;
    setState(() {
      _currentPath = path;
      _items = <FileSystemEntity>[];
    });
    await _loadItems();
  }

  void _goBack() {
    final parent = Directory(_currentPath).parent.path;
    if (parent != _currentPath) {
      _navigateTo(parent);
    }
  }

  String _getFileName(FileSystemEntity item) => item.path.split('/').last;
  IconData _getIcon(FileSystemEntity item) =>
      item is Directory ? Icons.folder : Icons.insert_drive_file;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final background = Theme.of(context).scaffoldBackgroundColor;

    if (_checkingPermission) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(title: const Text('مدير الملفات')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(title: const Text('مدير الملفات')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_off_outlined, size: 56, color: primary),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'يلزم منح إذن الوصول إلى الملفات.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _checkPermission,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('طلب الإذن مجددًا'),
                ),
                TextButton(
                  onPressed: openAppSettings,
                  child: const Text('فتح إعدادات التطبيق'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(_getFileName(Directory(_currentPath))),
        leading: IconButton(
          tooltip: 'المجلد السابق',
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentPath == '/' ? null : _goBack,
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loadItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 42, color: primary),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadItems,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open, size: 48, color: primary),
                          const SizedBox(height: 12),
                          const Text('هذا المجلد فارغ'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final isDirectory = item is Directory;
                        return ListTile(
                          leading: Icon(
                            _getIcon(item),
                            color: isDirectory ? primary : null,
                          ),
                          title: Text(
                            _getFileName(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: isDirectory ? const Text('مجلد') : null,
                          trailing: isDirectory
                              ? const Icon(Icons.chevron_left)
                              : null,
                          onTap: isDirectory ? () => _navigateTo(item.path) : null,
                        );
                      },
                    ),
    );
  }
}
