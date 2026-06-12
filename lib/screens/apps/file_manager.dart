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
  bool _isLoading = true;
  bool _hasPermission = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      final result = await Permission.storage.request();
      _hasPermission = result.isGranted;
    } else {
      _hasPermission = true;
    }
    
    if (_hasPermission) {
      _loadItems();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Storage permission required to access files';
      });
    }
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final dir = Directory(_currentPath);
      if (await dir.exists()) {
        final items = await dir.list().toList();
        items.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.split('/').last.compareTo(b.path.split('/').last);
        });
        setState(() {
          _items = items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Directory does not exist';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
      _loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('File Manager', style: TextStyle(color: Color(0xFF00BCD4))),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              const Text('Storage permission required', style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermission,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4)),
                child: const Text('Grant Permission', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_currentPath.split('/').last, style: const TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: _loadItems,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black.withOpacity(0.8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      _currentPath,
                      style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.1),
              child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
                : _items.isEmpty
                    ? const Center(child: Text('Empty folder', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final isDirectory = item is Directory;
                          final name = item.path.split('/').last;
                          return ListTile(
                            leading: Icon(
                              isDirectory ? Icons.folder : Icons.insert_drive_file,
                              color: isDirectory ? const Color(0xFF00BCD4) : Colors.white54,
                            ),
                            title: Text(name, style: const TextStyle(color: Colors.white)),
                            onTap: () {
                              if (isDirectory) {
                                _navigateTo(item.path);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
