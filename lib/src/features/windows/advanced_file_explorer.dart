import 'package:flutter/material.dart';
import 'dart:io';

class AdvancedFileExplorer extends StatefulWidget {
  const AdvancedFileExplorer({super.key});

  @override
  State<AdvancedFileExplorer> createState() => _AdvancedFileExplorerState();
}

class _AdvancedFileExplorerState extends State<AdvancedFileExplorer> {
  String _currentPath = '/sdcard';
  List<FileSystemEntity> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final dir = Directory(_currentPath);
    if (dir.existsSync()) {
      setState(() {
        _items = dir.listSync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('File Explorer - $_currentPath', style: const TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final isDirectory = item is Directory;
          return ListTile(
            leading: Icon(isDirectory ? Icons.folder : Icons.insert_drive_file, color: const Color(0xFF00FF41)),
            title: Text(item.path.split('/').last, style: const TextStyle(color: Colors.white)),
            onTap: () {
              if (isDirectory) {
                setState(() {
                  _currentPath = item.path;
                  _loadItems();
                });
              }
            },
          );
        },
      ),
    );
  }
}
