import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesBackupApp extends StatefulWidget {
  const NotesBackupApp({super.key});

  @override
  State<NotesBackupApp> createState() => _NotesBackupAppState();
}

class _NotesBackupAppState extends State<NotesBackupApp> {
  static const _notesKey = 'zion_notes';
  List<Map<String, dynamic>> _backups = [];
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  bool _isBackingUp = false;
  String _backupPath = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _backupPath = '${appDir.path}/notes_backups';
      await Directory(_backupPath).create(recursive: true);
      await _loadNotes();
      await _loadBackups();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notesKey);
    if (raw == null || raw.trim().isEmpty) {
      _notes = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _notes = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _notes = [];
      }
    } catch (_) {
      _notes = [];
    }
  }

  Future<void> _loadBackups() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dir = Directory(_backupPath);
      if (!await dir.exists()) return;
      final files = await dir.list().toList();
      final loaded = <Map<String, dynamic>>[];
      for (final file in files) {
        if (file is File && file.path.endsWith('.notesbackup')) {
          final stat = await file.stat();
          loaded.add({
            'name': file.uri.pathSegments.last,
            'path': file.path,
            'size': stat.size,
            'date': stat.modified,
          });
        }
      }
      loaded.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      _backups = loaded;
    } catch (_) {
      _backups = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    if (_isBackingUp) return;
    setState(() => _isBackingUp = true);
    try {
      await _loadNotes();
      final backupData = <String, dynamic>{
        'format': 1,
        'backup_time': DateTime.now().toIso8601String(),
        'notes': _notes,
      };
      final backupFile = File('$_backupPath/notes_backup_${DateTime.now().millisecondsSinceEpoch}.notesbackup');
      await backupFile.writeAsString(jsonEncode(backupData), flush: true);
      await _loadBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes backup created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text('This will replace all current notes. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final file = File(backup['path'] as String);
      if (!await file.exists()) throw const FileSystemException('Backup file not found');
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map || decoded['notes'] is! List) {
        throw const FormatException('Invalid notes backup format');
      }
      final restored = (decoded['notes'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notesKey, jsonEncode(restored));
      await _loadNotes();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored ${restored.length} notes successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteBackup(Map<String, dynamic> backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: const Text('Are you sure you want to delete this backup?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final file = File(backup['path'] as String);
      if (await file.exists()) await file.delete();
      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Notes Backup'),
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBackups)],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Current Notes', _notes.length.toString(), Icons.note),
                  _buildStatItem('Backups', _backups.length.toString(), Icons.backup),
                  _buildStatItem('Last Backup', _backups.isNotEmpty ? _formatDate(_backups.first['date'] as DateTime) : 'Never', Icons.history),
                ],
              ),
            ),
            const TabBar(tabs: [Tab(icon: Icon(Icons.backup), text: 'Backups'), Tab(icon: Icon(Icons.settings), text: 'Settings')]),
            Expanded(child: TabBarView(children: [_buildBackupsTab(), _buildSettingsTab()])),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isBackingUp ? null : _createBackup,
        child: _isBackingUp ? const CircularProgressIndicator() : const Icon(Icons.backup),
      ),
    );
  }

  Widget _buildBackupsTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_backups.isEmpty) return const Center(child: Text('No backups found', style: TextStyle(color: Colors.white54)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _backups.length,
      itemBuilder: (context, index) {
        final backup = _backups[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.archive),
            title: Text(backup['name'] as String),
            subtitle: Text('${_formatSize(backup['size'] as int)} • ${_formatDate(backup['date'] as DateTime)}'),
            trailing: Wrap(children: [
              IconButton(icon: const Icon(Icons.restore), onPressed: () => _restoreBackup(backup)),
              IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteBackup(backup)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(title: const Text('Backup Location'), subtitle: Text(_backupPath.isEmpty ? 'Initializing…' : _backupPath)),
        const ListTile(title: Text('Backup scope'), subtitle: Text('Notes stored by Zion OS in application preferences.')),
        const ListTile(title: Text('Device backup'), subtitle: Text('Not available to a normal application.')),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) => Column(children: [Icon(icon), const SizedBox(height: 4), Text(value), Text(label, style: const TextStyle(fontSize: 10))]);
}
