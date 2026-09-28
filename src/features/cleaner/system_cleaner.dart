import 'package:flutter/material.dart';
import 'dart:io';

class SystemCleaner extends StatefulWidget {
  const SystemCleaner({super.key});

  @override
  State<SystemCleaner> createState() => _SystemCleanerState();
}

class _SystemCleanerState extends State<SystemCleaner> {
  bool _isScanning = false;
  Map<String, int> _junkData = {};
  int _totalJunk = 0;

  Future<void> _scanJunk() async {
    setState(() {
      _isScanning = true;
      _junkData = {};
    });

    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _junkData = {
        'الملفات المؤقتة': 245,
        'ذاكرة التخزين المؤقت': 189,
        'سجلات النظام': 67,
        'الملفات المكررة': 34,
        'التنزيلات القديمة': 128,
      };
      _totalJunk = _junkData.values.reduce((a, b) => a + b);
      _isScanning = false;
    });
  }

  Future<void> _cleanJunk() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _junkData.clear();
      _totalJunk = 0;
      _isScanning = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم التنظيف بنجاح'), backgroundColor: Color(0xFF00FF41)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('منظف النظام', style: TextStyle(color: Color(0xFF00FF41))),
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
            // إحصائيات التخزين
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF00FF41).withOpacity(0.1), Colors.black],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.storage, color: Color(0xFF00FF41), size: 50),
                  const SizedBox(height: 10),
                  Text(
                    '${(_totalJunk / 1024).toStringAsFixed(2)} GB',
                    style: const TextStyle(color: Color(0xFF00FF41), fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const Text('ملفات غير ضرورية', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // أزرار التحكم
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanJunk,
                    icon: _isScanning ? const SizedBox(width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                    label: const Text('فحص'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF41), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _totalJunk > 0 && !_isScanning ? _cleanJunk : null,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('تنظيف'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // قائمة الملفات غير الضرورية
            Expanded(
              child: ListView.builder(
                itemCount: _junkData.length,
                itemBuilder: (context, index) {
                  final entry = _junkData.entries.elementAt(index);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(color: Colors.white)),
                        Text('${entry.value} MB', style: const TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
