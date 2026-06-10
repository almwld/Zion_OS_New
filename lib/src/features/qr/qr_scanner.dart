import 'package:flutter/material.dart';
import 'dart:math';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final List<String> _scanHistory = [];
  final TextEditingController _textController = TextEditingController();
  String _scanResult = '';

  void _simulateScan() {
    final random = Random();
    final results = [
      'https://www.google.com',
      'WIFI:S:MyWiFi;T:WPA;P:password123;;',
      'BEGIN:VCARD\nVERSION:3.0\nFN:John Doe\nTEL:+123456789\nEND:VCARD',
      'mailto:user@example.com',
      'tel:+123456789',
    ];
    
    setState(() {
      _scanResult = results[random.nextInt(results.length)];
      _scanHistory.insert(0, _scanResult);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scanned: $_scanResult')),
    );
  }

  void _generateQR() {
    if (_textController.text.isEmpty) return;
    
    setState(() {
      _scanResult = _textController.text;
      _scanHistory.insert(0, _textController.text);
    });
    
    _textController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code generated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: Colors.cyan.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildScannerPreview(),
            const SizedBox(height: 20),
            _buildQRGenerator(),
            const SizedBox(height: 20),
            _buildScanHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerPreview() {
    return GestureDetector(
      onTap: _simulateScan,
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.cyan, width: 2),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.qr_code_scanner, color: Colors.cyan, size: 80),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Tap to simulate scan', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRGenerator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('Generate QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter text or URL',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _generateQR,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                child: const Icon(Icons.qr_code),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistory() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: _scanHistory.isEmpty
                  ? const Center(child: Text('No scans yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _scanHistory.length,
                      itemBuilder: (ctx, i) => ListTile(
                        leading: const Icon(Icons.history, color: Colors.cyan),
                        title: Text(_scanHistory[i], style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, color: Colors.grey),
                          onPressed: () {},
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
