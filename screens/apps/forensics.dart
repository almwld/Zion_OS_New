import 'package:flutter/material.dart';
import 'dart:io';

class ForensicsApp extends StatefulWidget {
  const ForensicsApp({super.key});

  @override
  State<ForensicsApp> createState() => _ForensicsAppState();
}

class _ForensicsAppState extends State<ForensicsApp> {
  final TextEditingController _pathController = TextEditingController(text: '/sdcard');
  String _result = '';
  bool _isScanning = false;
  List<Map<String, dynamic>> _files = [];

  Future<void> _scanDirectory() async {
    final path = _pathController.text.trim();
    setState(() {
      _isScanning = true;
      _files.clear();
      _result = 'جاري فحص $path...';
    });

    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        final files = await dir.list().toList();
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            _files.add({
              'name': file.path.split('/').last,
              'size': _formatSize(stat.size),
              'modified': stat.modified.toLocal().toString().substring(0, 16),
            });
          }
        }
        setState(() {
          _result = '✅ تم العثور على ${_files.length} ملف';
          _isScanning = false;
        });
      } else {
        setState(() {
          _result = '❌ المسار غير موجود';
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ خطأ: $e';
        _isScanning = false;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _findSensitiveFiles() async {
    setState(() {
      _isScanning = true;
      _result = 'جاري البحث عن ملفات حساسة...';
    });

    final sensitive = ['password', 'key', 'secret', 'token', 'credential'];
    final found = <String>[];

    try {
      final result = await Process.run('find', [_pathController.text, '-type', 'f'], runInShell: true);
      final files = result.stdout.toString().split('\n');
      
      for (final file in files) {
        for (final word in sensitive) {
          if (file.toLowerCase().contains(word)) {
            found.add(file);
            break;
          }
        }
        if (found.length > 20) break;
      }
      
      setState(() {
        _result = found.isEmpty 
            ? 'لم يتم العثور على ملفات حساسة' 
            : 'تم العثور على ${found.length} ملف:\n${found.join('\n')}';
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ خطأ: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _calculateHash(String path) async {
    setState(() => _result = 'جاري حساب الهاش...');
    try {
      final result = await Process.run('md5sum', [path], runInShell: true);
      setState(() => _result = result.stdout.toString().trim());
    } catch (e) {
      setState(() => _result = '❌ خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Forensics', style: TextStyle(color: Color(0xFF00FF41))),
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
            // مسار الفحص
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'مسار الفحص',
                      labelStyle: TextStyle(color: Color(0xFF00FF41)),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _scanDirectory,
                  child: const Text('فحص'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF41), foregroundColor: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // أزرار التحليل
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _findSensitiveFiles,
                    icon: const Icon(Icons.search),
                    label: const Text('ملفات حساسة'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : () => _calculateHash(_pathController.text),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('حساب MD5'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // مؤشر التحميل
            if (_isScanning)
              const LinearProgressIndicator(color: Color(0xFF00FF41)),
            const SizedBox(height: 10),
            
            // النتيجة
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty ? 'نتائج التحليل ستظهر هنا...' : _result,
                    style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            
            // قائمة الملفات
            if (_files.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file, color: Color(0xFF00FF41)),
                      title: Text(file['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${file['size']} | ${file['modified']}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
