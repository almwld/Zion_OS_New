import 'package:flutter/material.dart';
import '../../core/services/backup_service.dart';

class BackupCenter extends StatefulWidget {
  const BackupCenter({super.key});

  @override
  State<BackupCenter> createState() => _BackupCenterState();
}

class _BackupCenterState extends State<BackupCenter> {
  final BackupService _backupService = BackupService();
  final TextEditingController _backupNameController = TextEditingController();
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _backupService.init();
    await _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    _backups = await _backupService.getBackupHistory();
    setState(() => _isLoading = false);
  }

  Future<void> _createBackup() async {
    if (_backupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter backup name'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isCreating = true);
    
    final result = await _backupService.createBackup(_backupNameController.text);
    
    setState(() => _isCreating = false);
    
    if (result['success']) {
      _backupNameController.clear();
      await _loadBackups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup created: ${_backupService.formatSize(result['size'])}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup', style: TextStyle(color: Color(0xFF00BCD4))),
        content: Text('Restore "${backup['name']}"? This will overwrite current settings.', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore', style: TextStyle(color: Color(0xFF00BCD4)))),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      final result = await _backupService.restoreBackup(backup['path']);
      
      setState(() => _isLoading = false);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored ${result['restored_items']} items'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteBackup(Map<String, dynamic> backup) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup', style: TextStyle(color: Color(0xFF00BCD4))),
        content: Text('Delete "${backup['name']}"?', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _backupService.deleteBackup(backup['path']);
      await _loadBackups();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup deleted'), backgroundColor: Color(0xFF00BCD4)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Backup & Restore', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Create Backup Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.backup, color: Colors.white, size: 50),
                  const SizedBox(height: 15),
                  const Text('Create New Backup', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _backupNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Backup name',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createBackup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00BCD4),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isCreating
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('CREATE BACKUP', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Statistics Card
            FutureBuilder(
              future: _backupService.getBackupStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final stats = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total Backups', '${stats['total_backups']}', Icons.archive),
                      _buildStatItem('Total Size', _backupService.formatSize(stats['total_size']), Icons.storage),
                      _buildStatItem('Last Backup', stats['last_backup'] != null 
                          ? _formatDate(stats['last_backup']) 
                          : 'Never', Icons.history),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Backup History
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backup History', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
                  else if (_backups.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No backups found', style: TextStyle(color: Colors.white38)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _backups.length,
                      itemBuilder: (context, index) {
                        final backup = _backups[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BCD4).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.archive, color: Color(0xFF00BCD4), size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(backup['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _backupService.formatSize(backup['size']),
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                    Text(
                                      _formatDate(backup['timestamp']),
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.restore, color: Color(0xFF00BCD4)),
                                onPressed: () => _restoreBackup(backup),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteBackup(backup),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00BCD4), size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
