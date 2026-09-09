import 'package:flutter/material.dart';

import '../../core/services/backup_service.dart';

class BackupManagerApp extends StatefulWidget {
  const BackupManagerApp({super.key});

  @override
  State<BackupManagerApp> createState() => _BackupManagerAppState();
}

class _BackupManagerAppState extends State<BackupManagerApp> {
  final BackupService _service = BackupService();
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;
  bool _isBackingUp = false;
  String _backupPath = '';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.init();
      await _reload();
      final history = await _service.getBackupHistory();
      if (history.isNotEmpty && history.first['path'] is String) {
        _backupPath = (history.first['path'] as String).replaceFirst(RegExp(r'/[^/]+$'), '');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reload() async {
    final history = await _service.getBackupHistory();
    if (!mounted) return;
    setState(() {
      _backups = history.where((b) => b['path'] is String).toList();
      _isLoading = false;
    });
  }

  Future<void> _createBackup() async {
    if (_isBackingUp) return;
    setState(() => _isBackingUp = true);
    try {
      await _service.init();
      final result = await _service.createBackup('Zion_Settings');
      if (!mounted) return;
      if (result['success'] == true) {
        await _reload();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup created successfully')));
      } else {
        throw StateError(result['error']?.toString() ?? 'Backup failed');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text('This will overwrite current application settings. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final path = backup['path'] as String;
      final result = await _service.restoreBackup(path);
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restored ${result['restored_items'] ?? 0} settings successfully')));
      } else {
        throw StateError(result['error']?.toString() ?? 'Restore failed');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red));
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
      await _service.deleteBackup(backup['path'] as String);
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red));
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
    final totalSize = _backups.fold<int>(0, (sum, b) => sum + ((b['size'] as num?)?.toInt() ?? 0));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Backup Manager'),
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _reload)],
        bottom: TabBar(
          onTap: (index) => setState(() => _selectedTab = index),
          tabs: const [Tab(icon: Icon(Icons.backup), text: 'Backups'), Tab(icon: Icon(Icons.settings), text: 'Settings')],
        ),
      ),
      body: IndexedStack(index: _selectedTab, children: [_buildBackupsTab(totalSize), _buildSettingsTab()]),
      floatingActionButton: FloatingActionButton(onPressed: _isBackingUp ? null : _createBackup, child: _isBackingUp ? const CircularProgressIndicator() : const Icon(Icons.backup)),
    );
  }

  Widget _buildBackupsTab(int totalSize) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_backups.isEmpty) return const Center(child: Text('No backups found', style: TextStyle(color: Colors.white54)));
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('Backups', '${_backups.length}', Icons.archive),
        _stat('Total Size', _formatSize(totalSize), Icons.storage),
      ])),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _backups.length,
        itemBuilder: (context, index) {
          final backup = _backups[index];
          final date = DateTime.tryParse(backup['timestamp']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return Card(child: ListTile(
            leading: const Icon(Icons.archive),
            title: Text(backup['name']?.toString() ?? 'Zion Backup'),
            subtitle: Text('${_formatSize((backup['size'] as num?)?.toInt() ?? 0)} • ${_formatDate(date)}'),
            trailing: Wrap(children: [
              IconButton(icon: const Icon(Icons.restore), onPressed: () => _restoreBackup(backup)),
              IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteBackup(backup)),
            ]),
          ));
        },
      )),
    ]);
  }

  Widget _buildSettingsTab() => ListView(padding: const EdgeInsets.all(16), children: [
    ListTile(title: const Text('Backup scope'), subtitle: const Text('Zion OS application preferences and settings.')),
    ListTile(title: const Text('Backup location'), subtitle: Text(_backupPath.isEmpty ? 'Application-private storage' : _backupPath)),
    const ListTile(title: Text('Device backup'), subtitle: Text('Not available to a normal application.')),
  ]);

  Widget _stat(String label, String value, IconData icon) => Column(children: [Icon(icon), const SizedBox(height: 4), Text(value), Text(label, style: const TextStyle(fontSize: 10))]);
}
