import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class FileManagerApp extends StatefulWidget {
  const FileManagerApp({super.key});

  @override
  State<FileManagerApp> createState() => _FileManagerAppState();
}

class _FileManagerAppState extends State<FileManagerApp> {
  String _currentPath = '/storage/emulated/0';
  List<FileSystemEntity> _items = [];
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.storage.request();
    setState(() {
      _hasPermission = status.isGranted;
      if (_hasPermission) _loadItems();
    });
  }

  Future<void> _loadItems() async {
    final dir = Directory(_currentPath);
    if (await dir.exists()) {
      final items = await dir.list().toList();
      items.sort((a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));
      setState(() => _items = items);
    }
  }

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
      _loadItems();
    });
  }

  void _goBack() {
    final parent = Directory(_currentPath).parent.path;
    if (parent != _currentPath) _navigateTo(parent);
  }

  String _getFileName(FileSystemEntity item) => item.path.split('/').last;
  IconData _getIcon(FileSystemEntity item) => item is Directory ? Icons.folder : Icons.insert_drive_file;
  String _formatSize(int bytes) => bytes < 1024 ? '$bytes B' : bytes < 1048576 ? '${(bytes / 1024).toStringAsFixed(1)} KB' : '${(bytes / 1048576).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('File Manager', style: TextStyle(color: Color(0xFF00BCD4))), backgroundColor: Colors.black),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Storage Permission Required', style: TextStyle(color: Colors.white38)),
            ElevatedButton(onPressed: _checkPermission, child: const Text('Grant Permission')),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_currentPath.split('/').last, style: const TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)), onPressed: _goBack),
      ),
      body: _items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final item = _items[i];
                return ListTile(
                  leading: Icon(_getIcon(item), color: const Color(0xFF00BCD4)),
                  title: Text(_getFileName(item), style: const TextStyle(color: Colors.white)),
                  onTap: () => item is Directory ? _navigateTo(item.path) : null,
                );
              },
            ),
    );
  }
}
