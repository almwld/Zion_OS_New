import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ZionFileManager extends StatefulWidget {
  const ZionFileManager({super.key});

  @override
  State<ZionFileManager> createState() => _ZionFileManagerState();
}

class _ZionFileManagerState extends State<ZionFileManager> {
  Directory _currentDirectory = Directory('/storage/emulated/0');
  List<FileSystemEntity> _items = [];
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    try {
      final items = await _currentDirectory.list().toList();
      items.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.compareTo(b.path);
      });
      setState(() {
        _items = items;
        _currentPath = _currentDirectory.path;
      });
    } catch (e) {
      debugPrint('Error loading directory: $e');
    }
  }

  void _navigateTo(Directory dir) {
    setState(() {
      _currentDirectory = dir;
      _loadDirectory();
    });
  }

  void _navigateUp() {
    if (_currentDirectory.path != '/') {
      final parent = Directory(_currentDirectory.path).parent;
      setState(() {
        _currentDirectory = parent;
        _loadDirectory();
      });
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        backgroundColor: Colors.grey.shade900,
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newFolder = Directory('${_currentDirectory.path}/${controller.text}');
              await newFolder.create();
              Navigator.pop(ctx);
              _loadDirectory();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_currentPath, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.blue.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateUp,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: _createFolder,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDirectory,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final isDirectory = item is Directory;
          final name = item.path.split('/').last;
          final icon = isDirectory ? Icons.folder : Icons.insert_drive_file;
          final color = isDirectory ? Colors.blue : Colors.grey;
          
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(name, style: const TextStyle(color: Colors.white)),
            onTap: () {
              if (isDirectory) {
                _navigateTo(item as Directory);
              }
            },
          );
        },
      ),
    );
  }
}
