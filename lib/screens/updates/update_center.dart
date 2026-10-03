import 'package:flutter/material.dart';
import '../../zion_ota_system.dart';

class UpdateCenter extends StatefulWidget {
  const UpdateCenter({super.key});

  @override
  State<UpdateCenter> createState() => _UpdateCenterState();
}

class _UpdateCenterState extends State<UpdateCenter> {
  final ZionOTASystem _ota = ZionOTASystem();
  bool _autoCheck = false;
  bool _autoDownload = false;
  String _status = 'OTA unavailable: trusted signed source is not configured';
  
  List<Map<String, dynamic>> _updateHistory = [
    {'version': '4.0.0', 'date': '2025-04-15', 'changes': 'UI redesign, New tools, Performance improvements'},
    {'version': '3.3.0', 'date': '2025-03-01', 'changes': 'Added Security Center, Fixed bugs'},
    {'version': '3.2.0', 'date': '2025-02-10', 'changes': 'Network tools update, Stability fixes'},
    {'version': '3.1.0', 'date': '2025-01-20', 'changes': 'Initial release with core features'},
  ];

  @override
  void initState() {
    super.initState();
    _ota.addListener(_onOtaChanged);
  }

  @override
  void dispose() {
    _ota.removeListener(_onOtaChanged);
    _ota.dispose();
    super.dispose();
  }

  void _onOtaChanged() {
    if (!mounted) return;
    setState(() {
      _status = _ota.error ?? 'OTA unavailable: no trusted signed update is configured';
    });
  }

  Future<void> _checkForUpdates() async {
    await _ota.checkForUpdates();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_status), backgroundColor: const Color(0xFF00BCD4)),
    );
  }

  Future<void> _downloadUpdate() => _ota.downloadUpdate();
  Future<void> _installUpdate() => _ota.installUpdate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Update Center', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: _checkForUpdates,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current Version Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.system_update, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'Zion OS $_currentVersion',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _status,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  if (_ota.isChecking)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    ElevatedButton.icon(
                      onPressed: _checkForUpdates,
                      icon: const Icon(Icons.search),
                      label: const Text('Check for Updates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00BCD4),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Settings Section
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
                  const Text('Update Settings', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildSwitchItem('Auto-check for updates', _autoCheck, (v) => setState(() => _autoCheck = v)),
                  _buildSwitchItem('Auto-download updates', _autoDownload, (v) => setState(() => _autoDownload = v)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Available Updates
            if (_ota.availableUpdate != null) ...[
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
                    const Text('Available Update', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(_ota.availableUpdate!.description, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _ota.isDownloading ? null : _downloadUpdate,
                          child: const Text('Download'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _ota.isInstalling ? null : _installUpdate,
                          child: const Text('Install'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Update History
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
                  const Text('Update History', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._updateHistory.map((update) => _buildHistoryItem(update)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // System Info
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
                  const Text('System Information', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildInfoRow('OTA configured', _ota.isConfigured ? 'Yes' : 'No'),
                  _buildInfoRow('Update source', _ota.isConfigured ? 'Configured' : 'Trusted source required'),
                  _buildInfoRow('Install path', 'AOSP / Recovery required'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Beta Program
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science, color: Color(0xFF00BCD4), size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Beta Program', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                        const Text('Get early access to new features', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: false,
                    onChanged: (_) {},
                    activeColor: const Color(0xFF00BCD4),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, color: Color(0xFF00BCD4), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version ${update['version']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(update['date'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                Text(update['changes'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
