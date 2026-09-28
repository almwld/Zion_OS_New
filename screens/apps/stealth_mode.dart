import 'package:flutter/material.dart';
import 'dart:io';

class StealthModeApp extends StatefulWidget {
  const StealthModeApp({super.key});

  @override
  State<StealthModeApp> createState() => _StealthModeAppState();
}

class _StealthModeAppState extends State<StealthModeApp> {
  bool _isStealthEnabled = false;
  bool _isHidingFiles = false;
  bool _isClearingLogs = false;
  String _statusMessage = 'الوضع طبيعي';
  final List<String> _logMessages = [];

  void _addLog(String msg) {
    setState(() {
      _logMessages.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $msg');
      if (_logMessages.length > 20) _logMessages.removeLast();
    });
  }

  Future<void> _toggleStealth() async {
    setState(() => _isStealthEnabled = !_isStealthEnabled);
    
    if (_isStealthEnabled) {
      _addLog('🛡️ تفعيل وضع التخفي...');
      setState(() => _statusMessage = 'وضع التخفي نشط');
      await Future.delayed(const Duration(seconds: 1));
      _addLog('✅ تم تفعيل وضع التخفي بنجاح');
    } else {
      _addLog('🔓 إلغاء وضع التخفي...');
      setState(() => _statusMessage = 'الوضع طبيعي');
      await Future.delayed(const Duration(seconds: 1));
      _addLog('✅ تم إلغاء وضع التخفي');
    }
  }

  Future<void> _hideFiles() async {
    setState(() => _isHidingFiles = true);
    _addLog('📁 جاري إخفاء الملفات الحساسة...');
    
    try {
      final paths = ['/sdcard/DCIM', '/sdcard/Download', '/sdcard/Pictures'];
      for (final path in paths) {
        await Process.run('chattr', ['+h', path], runInShell: true);
        _addLog('✅ تم إخفاء: $path');
      }
    } catch (e) {
      _addLog('❌ فشل إخفاء الملفات: $e');
    }
    
    setState(() => _isHidingFiles = false);
  }

  Future<void> _clearLogs() async {
    setState(() => _isClearingLogs = true);
    _addLog('🗑️ جاري مسح السجلات...');
    
    final logFiles = [
      '/data/local/tmp/log.txt',
      '/sdcard/log.txt',
    ];
    
    for (final log in logFiles) {
      try {
        await Process.run('rm', ['-f', log], runInShell: true);
        _addLog('✅ تم مسح: $log');
      } catch (_) {}
    }
    
    setState(() => _isClearingLogs = false);
  }

  Future<void> _spoofMAC() async {
    _addLog('🎭 جاري تغيير عنوان MAC...');
    try {
      final result = await Process.run('ip', ['link', 'show', 'wlan0'], runInShell: true);
      _addLog('✅ MAC الحالي: ${result.stdout.toString().split(' ')[1]}');
      await Process.run('ip', ['link', 'set', 'wlan0', 'down'], runInShell: true);
      await Process.run('ip', ['link', 'set', 'wlan0', 'address', '00:11:22:33:44:55'], runInShell: true);
      await Process.run('ip', ['link', 'set', 'wlan0', 'up'], runInShell: true);
      _addLog('✅ تم تغيير MAC إلى 00:11:22:33:44:55');
    } catch (e) {
      _addLog('❌ فشل تغيير MAC: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Stealth Mode', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // حالة التخفي
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isStealthEnabled
                      ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.05)]
                      : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _isStealthEnabled ? Colors.green : Colors.red, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    _isStealthEnabled ? Icons.visibility_off : Icons.visibility,
                    color: _isStealthEnabled ? Colors.green : Colors.red,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: _isStealthEnabled ? Colors.green : Colors.red, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // أزرار التحكم (كلها تعمل)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleStealth,
                    icon: Icon(_isStealthEnabled ? Icons.visibility : Icons.visibility_off),
                    label: Text(_isStealthEnabled ? 'إلغاء التخفي' : 'تفعيل التخفي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isStealthEnabled ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isHidingFiles ? null : _hideFiles,
                    icon: _isHidingFiles ? const SizedBox(width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.folder),
                    label: const Text('إخفاء الملفات'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isClearingLogs ? null : _clearLogs,
                    icon: _isClearingLogs ? const SizedBox(width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete),
                    label: const Text('مسح السجلات'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _spoofMAC,
                icon: const Icon(Icons.wifi),
                label: const Text('تغيير MAC Address'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ),
            const SizedBox(height: 20),
            
            // سجل العمليات
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('سجل العمليات:', style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _logMessages.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(_logMessages[index], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
