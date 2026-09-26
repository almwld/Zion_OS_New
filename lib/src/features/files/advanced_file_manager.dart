import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/theme_manager.dart';
import '../../widgets/glassmorphism.dart';

class AdvancedFileManager extends StatefulWidget {
  const AdvancedFileManager({super.key});

  @override
  State<AdvancedFileManager> createState() => _AdvancedFileManagerState();
}

class _AdvancedFileManagerState extends State<AdvancedFileManager> {
  final ThemeManager _themeManager = ThemeManager();
  Directory _currentDirectory = Directory('/storage/emulated/0');
  List<FileSystemEntity> _items = [];
  List<FileSystemEntity> _selectedItems = [];
  List<FileSystemEntity> _clipboardItems = [];
  bool _clipboardIsMove = false;
  String _currentPath = '';
  bool _isLoading = true;
  bool _isSelecting = false;
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.grid;

  enum ViewMode { grid, list }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadDirectory();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      setState(() {
        _currentDirectory = Directory(_currentDirectory.path).parent;
        _loadDirectory();
      });
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    await showDialog(
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

  Future<void> _deleteItem(FileSystemEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete ${item.path.split('/').last}?'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        if (item is File) await item.delete();
        else if (item is Directory) await item.delete(recursive: true);
        _loadDirectory();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _renameItem(FileSystemEntity item) async {
    final controller = TextEditingController(text: item.path.split('/').last);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        backgroundColor: Colors.grey.shade900,
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'New name',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newPath = '${_currentDirectory.path}/${controller.text}';
              await item.rename(newPath);
              Navigator.pop(ctx);
              _loadDirectory();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  void _toggleSelection(FileSystemEntity item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
      _isSelecting = false;
    });
  }

  void _copySelected() {
    setState(() {
      _clipboardItems = List<FileSystemEntity>.from(_selectedItems);
      _clipboardIsMove = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_clipboardItems.length} item(s) copied')),
    );
  }

  void _moveSelected() {
    setState(() {
      _clipboardItems = List<FileSystemEntity>.from(_selectedItems);
      _clipboardIsMove = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_clipboardItems.length} item(s) ready to move')),
    );
  }

  Future<void> _pasteClipboard() async {
    if (_clipboardItems.isEmpty) return;
    try {
      for (final source in List<FileSystemEntity>.from(_clipboardItems)) {
        final name = source.path.split(Platform.pathSeparator).last;
        final targetPath = await _uniqueTargetPath(_currentDirectory, name);
        if (source is File) {
          await source.copy(targetPath);
        } else if (source is Directory) {
          await _copyDirectory(source, Directory(targetPath));
        }
        if (_clipboardIsMove) {
          await source.delete(recursive: source is Directory);
        }
      }
      setState(() => _clipboardItems.clear());
      await _loadDirectory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste completed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paste failed: $e')));
      }
    }
  }

  Future<String> _uniqueTargetPath(Directory directory, String name) async {
    var candidate = '${directory.path}/$name';
    if (FileSystemEntity.typeSync(candidate) == FileSystemEntityType.notFound) return candidate;
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final ext = dot > 0 ? name.substring(dot) : '';
    for (var i = 1; i < 10000; i++) {
      candidate = '${directory.path}/$base copy$i$ext';
      if (FileSystemEntity.typeSync(candidate) == FileSystemEntityType.notFound) return candidate;
    }
    throw StateError('Unable to create a unique destination');
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      final destination = '${target.path}/$name';
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await entity.copy(destination);
      }
    }
  }

  List<FileSystemEntity> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    return _items.where((item) =>
      item.path.split('/').last.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp': return Icons.image;
      case 'mp3': case 'wav': case 'flac': case 'ogg': return Icons.audiotrack;
      case 'mp4': case 'avi': case 'mkv': case 'mov': return Icons.video_library;
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'xls': case 'xlsx': return Icons.table_chart;
      case 'ppt': case 'pptx': return Icons.slideshow;
      case 'zip': case 'rar': case '7z': case 'tar': case 'gz': return Icons.archive;
      case 'apk': return Icons.android;
      case 'dart': case 'txt': case 'json': case 'xml': return Icons.code;
      default: return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeManager.currentTheme;
    
    return Scaffold(
      backgroundColor: theme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(child: Text('No files found', style: TextStyle(color: Colors.grey)))
                    : _viewMode == ViewMode.grid
                        ? _buildGridView()
                        : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_currentPath, style: const TextStyle(fontSize: 12)),
      backgroundColor: _themeManager.currentTheme.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _navigateUp,
      ),
      actions: [
        if (_isSelecting)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearSelection,
          ),
        IconButton(
          icon: Icon(_viewMode == ViewMode.grid ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid),
        ),
        IconButton(
          icon: const Icon(Icons.folder),
          onPressed: _createFolder,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDirectory,
        ),
        if (_selectedItems.isNotEmpty)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copy') _copySelected();
              if (value == 'move') _moveSelected();
              if (value == 'delete') {
                for (final item in _selectedItems) {
                  _deleteItem(item);
                }
                _clearSelection();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'copy', child: Text('Copy')),
              const PopupMenuItem(value: 'move', child: Text('Move')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        if (_clipboardItems.isNotEmpty)
          IconButton(
            icon: Icon(_clipboardIsMove ? Icons.drive_file_move : Icons.content_paste),
            tooltip: 'Paste',
            onPressed: _pasteClipboard,
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade900,
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search files...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.black,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (ctx, i) {
        final item = _filteredItems[i];
        final isDirectory = item is Directory;
        final name = item.path.split('/').last;
        final icon = isDirectory ? Icons.folder : _getFileIcon(name);
        final isSelected = _selectedItems.contains(item);
        
        return GestureDetector(
          onTap: () {
            if (_isSelecting) {
              _toggleSelection(item);
            } else if (isDirectory) {
              _navigateTo(item as Directory);
            }
          },
          onLongPress: () {
            setState(() {
              _isSelecting = true;
              _toggleSelection(item);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? _themeManager.currentTheme.accent.withOpacity(0.2) : Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: _themeManager.currentTheme.accent, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isDirectory ? Colors.orange : _themeManager.currentTheme.accent, size: 48),
                const SizedBox(height: 8),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (!isDirectory)
                  Text(_formatSize(item.statSync().size), style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (ctx, i) {
        final item = _filteredItems[i];
        final isDirectory = item is Directory;
        final name = item.path.split('/').last;
        final icon = isDirectory ? Icons.folder : _getFileIcon(name);
        final isSelected = _selectedItems.contains(item);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? _themeManager.currentTheme.accent.withOpacity(0.2) : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(icon, color: isDirectory ? Colors.orange : _themeManager.currentTheme.accent),
            title: Text(name, style: const TextStyle(color: Colors.white)),
            subtitle: isDirectory ? null : Text(_formatSize(item.statSync().size), style: const TextStyle(color: Colors.grey)),
            trailing: isDirectory
                ? null
                : IconButton(
                    icon: const Icon(Icons.share, color: Colors.green),
                    onPressed: () => _shareFile(item as File),
                  ),
            onTap: () {
              if (_isSelecting) {
                _toggleSelection(item);
              } else if (isDirectory) {
                _navigateTo(item as Directory);
              }
            },
            onLongPress: () {
              setState(() {
                _isSelecting = true;
                _toggleSelection(item);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    if (_isSelecting) return null;
    
    return FloatingActionButton(
      onPressed: _createFolder,
      backgroundColor: _themeManager.currentTheme.accent,
      child: const Icon(Icons.folder),
    );
  }
}
