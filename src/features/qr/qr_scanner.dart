import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// QR UI without fabricated scan results. Camera decoding requires a dedicated
/// barcode scanner implementation and is reported as unavailable until wired.
class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final List<String> _history = [];
  final TextEditingController _textController = TextEditingController();
  String _result = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showScannerUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ماسح QR بالكاميرا غير مهيأ بعد؛ لن يتم إنشاء نتيجة وهمية.')),
    );
  }

  void _saveManualValue() {
    final value = _textController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _result = value;
      _history.insert(0, value);
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('QR Scanner'), backgroundColor: Colors.cyan.shade900),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: _showScannerUnavailable,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyan, width: 2),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.cyan, size: 80),
                    SizedBox(height: 16),
                    Text('ماسح الكاميرا غير مهيأ', style: TextStyle(color: Colors.white)),
                    SizedBox(height: 6),
                    Text('لن يتم اختلاق نتائج مسح', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'إدخال بيانات QR يدويًا', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: _saveManualValue, child: const Icon(Icons.save)),
                ],
              ),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Text('آخر قيمة', style: TextStyle(color: Colors.white))),
                IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: _result)), icon: const Icon(Icons.copy, color: Colors.cyan)),
              ]),
              Align(alignment: Alignment.centerLeft, child: Text(_result, style: const TextStyle(color: Colors.cyan))),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _history.isEmpty
                  ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (ctx, i) => ListTile(
                        leading: const Icon(Icons.history, color: Colors.cyan),
                        title: Text(_history[i], style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
