import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class UpdateCenter extends StatefulWidget {
  const UpdateCenter({super.key});

  @override
  State<UpdateCenter> createState() => _UpdateCenterState();
}

class _UpdateCenterState extends State<UpdateCenter> {
  bool _autoCheck = true;
  bool _autoDownload = false;
  bool _isChecking = false;
  String _currentVersion = '4.0.0';
  String _status = 'Up to date';
  
  List<Map<String, dynamic>> _updateHistory = [
    {'version': '4.0.0', 'date': '2025-04-15', 'changes': 'UI redesign, New tools, Performance improvements'},
    {'version': '3.3.0', 'date': '2025-03-01', 'changes': 'Added Security Center, Fixed bugs'},
    {'version': '3.2.0', 'date': '2025-02-10', 'changes': 'Network tools update, Stability fixes'},
    {'version': '3.1.0', 'date': '2025-01-20', 'changes': 'Initial release with core features'},
  ];

  List<Map<String, dynamic>> _availableUpdates = [
    {'name': 'Security Database', 'version': '2025.04.15', 'size': '2.5 MB', 'type': 'Database'},
    {'name': 'Tool Signatures', 'version': '2025.04.14', 'size': '1.8 MB', 'type': 'Signatures'},
    {'name': 'Language Pack', 'version': '2025.04.10', 'size': '3.2 MB', 'type': 'Language'},
  ];

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _status = 'Checking for updates...';
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isChecking = false;
      _status = 'Up to date';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No new updates available'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  Future<void> _downloadUpdate(Map<String, dynamic> update) async {
    setState(() {
      _status = 'Downloading ${update['name']}...';
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _status = 'Download complete';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${update['name']} downloaded successfully'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

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
                  if (_isChecking)
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
            if (_availableUpdates.isNotEmpty) ...[
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
                    const Text('Available Updates', style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ..._availableUpdates.map((update) => _buildUpdateItem(update)),
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
                  _buildInfoRow('OS Version', 'Android 14+'),
                  _buildInfoRow('Build Number', 'ZOS-2027.04.15'),
                  _buildInfoRow('Security Patch', '2025-04-05'),
                  _buildInfoRow('Last Update', '2025-04-15'),
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

  Widget _buildUpdateItem(Map<String, dynamic> update) {
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
            child: const Icon(Icons.download, color: Color(0xFF00BCD4), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(update['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Version ${update['version']} • ${update['size']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _downloadUpdate(update),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            ),
            child: const Text('Update'),
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
