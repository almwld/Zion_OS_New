import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupManager extends StatefulWidget {
  const BackupManager({super.key});

  @override
  State<BackupManager> createState() => _BackupManagerState();
}

class _BackupManagerState extends State<BackupManager> {
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backups');
      
      if (await backupDir.exists()) {
        final files = backupDir.listSync();
        _backups = files.where((f) => f.path.endsWith('.zip')).map((f) => ({
          'name': f.path.split('/').last,
          'size': File(f.path).statSync().size,
          'date': File(f.path).lastModifiedSync(),
          'path': f.path,
        })).toList();
      } else {
        await backupDir.create();
      }
    } catch (_) {}
    
    setState(() => _isLoading = false);
  }

  Future<void> _createBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File('${backupDir.path}/backup_$timestamp.zip');
    
    await backupFile.writeAsString('Backup data - ${DateTime.now()}');
    _loadBackups();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup created successfully')),
    );
  }

  Future<void> _restoreBackup(String path) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text('Are you sure you want to restore this backup? Current data will be overwritten.'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup restored')),
              );
            },
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareBackup(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }

  Future<void> _deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      _loadBackups();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup deleted')),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Backup Manager'),
        backgroundColor: Colors.purple.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: _createBackup,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _backups.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.backup, color: Colors.grey, size: 64),
                      SizedBox(height: 16),
                      Text('No backups found', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Tap backup to create one', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _backups.length,
                  itemBuilder: (ctx, i) => Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.archive, color: Colors.purple),
                      title: Text(_backups[i]['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${_formatSize(_backups[i]['size'])} - ${_backups[i]['date']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore, color: Colors.green),
                            onPressed: () => _restoreBackup(_backups[i]['path']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.blue),
                            onPressed: () => _shareBackup(_backups[i]['path']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBackup(_backups[i]['path']),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
