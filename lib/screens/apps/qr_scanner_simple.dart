import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRScannerApp extends StatefulWidget {
  const QRScannerApp({super.key});

  @override
  State<QRScannerApp> createState() => _QRScannerAppState();
}

class _QRScannerAppState extends State<QRScannerApp> {
  final TextEditingController _qrTextController = TextEditingController();
  String _scannedResult = '';
  List<Map<String, String>> _scanHistory = [];

  void _simulateScan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF00BCD4)),
            const SizedBox(height: 16),
            const Text('Camera access simulation', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _qrTextController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter QR content manually',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              final text = _qrTextController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _scannedResult = text;
                  _scanHistory.insert(0, {'code': text, 'time': DateTime.now().toIso8601String()});
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Scan History', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: _scanHistory.isEmpty
                  ? const Center(child: Text('No history', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: _scanHistory.length,
                      itemBuilder: (context, index) {
                        final item = _scanHistory[index];
                        return ListTile(
                          leading: const Icon(Icons.qr_code, color: Color(0xFF00BCD4)),
                          title: Text(item['code']!, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(_formatDate(item['time']!), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, color: Color(0xFF00BCD4), size: 18),
                            onPressed: () => _copyToClipboard(item['code']!),
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

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('QR Scanner', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF00BCD4)),
            onPressed: _showHistory,
            tooltip: 'History',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF00BCD4)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _simulateScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            if (_scannedResult.isNotEmpty) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Last Scanned:', style: TextStyle(color: Color(0xFF00BCD4))),
                    const SizedBox(height: 8),
                    SelectableText(_scannedResult, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(_scannedResult),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
