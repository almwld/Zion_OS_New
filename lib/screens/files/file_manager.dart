import 'package:flutter/material.dart';
import 'dart:io';

class FileManager extends StatefulWidget {
  const FileManager({super.key});

  @override
  State<FileManager> createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  String _currentPath = '/sdcard';
  List<FileSystemEntity> _items = [];
  List<FileSystemEntity> _selectedItems = [];
  bool _isSelecting = false;
  String _searchQuery = '';
  bool _showHidden = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final dir = Directory(_currentPath);
    if (dir.existsSync()) {
      setState(() {
        _items = dir.listSync()
            .where((item) => _showHidden || !item.path.split('/').last.startsWith('.'))
            .toList();
        _items.sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return a.path.split('/').last.compareTo(b.path.split('/').last);
        });
      });
    }
  }

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
      _selectedItems.clear();
      _isSelecting = false;
      _loadItems();
    });
  }

  void _goBack() {
    final parent = Directory(_currentPath).parent.path;
    if (parent != _currentPath) {
      _navigateTo(parent);
    }
  }

  void _toggleSelect(FileSystemEntity item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
      _isSelecting = _selectedItems.isNotEmpty;
    });
  }

  void _deleteSelected() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Files', style: TextStyle(color: Color(0xFF00BCD4))),
        content: Text('Delete ${_selectedItems.length} item(s)?', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      for (final item in _selectedItems) {
        try {
          if (item is Directory) {
            item.deleteSync(recursive: true);
          } else {
            item.deleteSync();
          }
        } catch (_) {}
      }
      _selectedItems.clear();
      _isSelecting = false;
      _loadItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted successfully'), backgroundColor: Color(0xFF00BCD4)),
      );
    }
  }

  void _createFolder() async {
    final controller = TextEditingController();
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Folder name',
            labelStyle: TextStyle(color: Color(0xFF00BCD4)),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create', style: TextStyle(color: Color(0xFF00BCD4)))),
        ],
      ),
    );
    
    if (confirmed != null && confirmed.isNotEmpty) {
      final newDir = Directory('$_currentPath/$confirmed');
      if (!newDir.existsSync()) {
        newDir.createSync();
        _loadItems();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder created'), backgroundColor: Color(0xFF00BCD4)),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _searchQuery.isEmpty
        ? _items
        : _items.where((item) => 
            item.path.split('/').last.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _currentPath.split('/').last,
          style: const TextStyle(color: Color(0xFF00BCD4)),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => _isSelecting ? setState(() {
            _selectedItems.clear();
            _isSelecting = false;
          }) : Navigator.pop(context),
        ),
        actions: [
          if (!_isSelecting) ...[
            IconButton(
              icon: Icon(_showHidden ? Icons.visibility : Icons.visibility_off, color: Color(0xFF00BCD4)),
              onPressed: () => setState(() { _showHidden = !_showHidden; _loadItems(); }),
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder, color: Color(0xFF00BCD4)),
              onPressed: _createFolder,
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
              onPressed: () => showSearch(
                context: context,
                delegate: FileSearchDelegate(_items, _navigateTo),
              ),
            ),
          ],
          if (_isSelecting && _selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: Column(
        children: [
          // Path Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black.withOpacity(0.8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Color(0xFF00BCD4), size: 18),
                  onPressed: _goBack,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _currentPath.split('/').asMap().entries.map((entry) {
                        final index = entry.key;
                        final part = entry.value;
                        if (part.isEmpty) return const SizedBox();
                        final path = '/' + _currentPath.split('/').sublist(0, index + 1).join('/');
                        return GestureDetector(
                          onTap: () => _navigateTo(path),
                          child: Row(
                            children: [
                              Text(part, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
                              if (index < _currentPath.split('/').length - 1)
                                const Icon(Icons.chevron_right, color: Color(0xFF00BCD4), size: 16),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Storage Info
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.storage, color: Color(0xFF00BCD4), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Storage', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: Colors.white24,
                        color: const Color(0xFF00BCD4),
                      ),
                    ],
                  ),
                ),
                const Text('12.5/32 GB', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12)),
              ],
            ),
          ),
          
          // File List
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text('Empty folder', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isDirectory = item is Directory;
                      final isSelected = _selectedItems.contains(item);
                      final name = item.path.split('/').last;
                      final size = isDirectory ? 0 : (item as File).lengthSync();
                      
                      return GestureDetector(
                        onTap: () => _isSelecting
                            ? _toggleSelect(item)
                            : isDirectory
                                ? _navigateTo(item.path)
                                : _openFile(item),
                        onLongPress: () => _toggleSelect(item),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00BCD4).withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isDirectory ? Icons.folder : _getFileIcon(name),
                                color: isDirectory ? const Color(0xFF00BCD4) : Colors.white54,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF00BCD4) : Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (!isDirectory)
                                      Text(
                                        _formatSize(size),
                                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Color(0xFF00BCD4), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String filename) {
    if (filename.endsWith('.jpg') || filename.endsWith('.png') || filename.endsWith('.gif')) {
      return Icons.image;
    } else if (filename.endsWith('.mp4') || filename.endsWith('.avi')) {
      return Icons.video_file;
    } else if (filename.endsWith('.mp3') || filename.endsWith('.wav')) {
      return Icons.audiotrack;
    } else if (filename.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (filename.endsWith('.txt') || filename.endsWith('.dart')) {
      return Icons.description;
    } else if (filename.endsWith('.apk')) {
      return Icons.android;
    }
    return Icons.insert_drive_file;
  }

  void _openFile(FileSystemEntity item) {
    // استعراض الملف (يمكن إضافة عارض مدمج لاحقاً)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open: ${item.path.split('/').last}'), backgroundColor: Color(0xFF00BCD4)),
    );
  }
}

class FileSearchDelegate extends SearchDelegate {
  final List<FileSystemEntity> items;
  final Function(String) onNavigate;

  FileSearchDelegate(this.items, this.onNavigate);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear, color: Color(0xFF00BCD4)),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results = items.where((item) =>
      item.path.split('/').last.toLowerCase().contains(query.toLowerCase())
    ).toList();
    
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: Icon(item is Directory ? Icons.folder : Icons.insert_drive_file, color: Color(0xFF00BCD4)),
          title: Text(item.path.split('/').last, style: const TextStyle(color: Colors.white)),
          subtitle: Text(item.path, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          onTap: () {
            close(context, null);
            if (item is Directory) onNavigate(item.path);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
