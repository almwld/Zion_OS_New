import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CryptoToolApp extends StatefulWidget {
  const CryptoToolApp({super.key});

  @override
  State<CryptoToolApp> createState() => _CryptoToolAppState();
}

class _CryptoToolAppState extends State<CryptoToolApp> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  String _output = '';
  String _selectedOperation = 'MD5';
  String _selectedMode = 'تشفير';

  final List<String> _operations = ['MD5', 'SHA1', 'SHA256', 'Base64 Encode', 'Base64 Decode', 'XOR'];
  final List<String> _modes = ['تشفير', 'فك تشفير'];

  // === وظائف حقيقية تعمل ===
  void _process() {
    final input = _inputController.text;
    if (input.isEmpty) {
      setState(() => _output = '⚠️ الرجاء إدخال النص');
      return;
    }

    setState(() => _output = 'جاري المعالجة...');

    switch (_selectedOperation) {
      case 'MD5':
        _output = md5.convert(utf8.encode(input)).toString();
        break;
      case 'SHA1':
        _output = sha1.convert(utf8.encode(input)).toString();
        break;
      case 'SHA256':
        _output = sha256.convert(utf8.encode(input)).toString();
        break;
      case 'Base64 Encode':
        _output = base64.encode(utf8.encode(input));
        break;
      case 'Base64 Decode':
        try {
          _output = utf8.decode(base64.decode(input));
        } catch (e) {
          _output = '❌ فك التشفير فشل: نص غير صالح';
        }
        break;
      case 'XOR':
        final key = _keyController.text;
        if (key.isEmpty) {
          _output = '⚠️ الرجاء إدخال المفتاح لعملية XOR';
          return;
        }
        if (_selectedMode == 'تشفير') {
          _output = _xorEncrypt(input, key);
        } else {
          _output = _xorDecrypt(input, key);
        }
        break;
    }
    setState(() {});
  }

  String _xorEncrypt(String text, String key) {
    final result = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final charCode = text.codeUnitAt(i) ^ key.codeUnitAt(i % key.length);
      result.write(String.fromCharCode(charCode));
    }
    return base64.encode(utf8.encode(result.toString()));
  }

  String _xorDecrypt(String text, String key) {
    try {
      final decoded = utf8.decode(base64.decode(text));
      final result = StringBuffer();
      for (var i = 0; i < decoded.length; i++) {
        final charCode = decoded.codeUnitAt(i) ^ key.codeUnitAt(i % key.length);
        result.write(String.fromCharCode(charCode));
      }
      return result.toString();
    } catch (e) {
      return '❌ فك التشفير فشل';
    }
  }

  void _clear() {
    _inputController.clear();
    _keyController.clear();
    setState(() => _output = '');
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _output));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ'), backgroundColor: Color(0xFF00FF41)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crypto Tool', style: TextStyle(color: Color(0xFF00FF41))),
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
            // اختيار العملية
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedOperation,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Color(0xFF00FF41)),
                  items: _operations.map((op) {
                    return DropdownMenuItem(value: op, child: Text(op));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedOperation = value!),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // اختيار وضع (لـ XOR فقط)
            if (_selectedOperation == 'XOR')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMode,
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Color(0xFF00FF41)),
                    items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (value) => setState(() => _selectedMode = value!),
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // حقل المفتاح (لـ XOR)
            if (_selectedOperation == 'XOR')
              TextField(
                controller: _keyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'المفتاح (Key)',
                  labelStyle: TextStyle(color: Color(0xFF00FF41)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41), width: 2)),
                ),
              ),
            const SizedBox(height: 10),

            // حقل الإدخال
            Expanded(
              flex: 2,
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'النص',
                  labelStyle: TextStyle(color: Color(0xFF00FF41)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41), width: 2)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // أزرار التحكم (كلها تعمل)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _process,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('تنفيذ'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF41), foregroundColor: Colors.black),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear),
                    label: const Text('مسح'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // حقل الإخراج مع زر نسخ
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _output.isEmpty ? 'النتيجة ستظهر هنا...' : _output,
                        style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                  if (_output.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFF00FF41), size: 20),
                        onPressed: _copyToClipboard,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
