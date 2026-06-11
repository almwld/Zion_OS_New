import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CryptoToolApp extends StatefulWidget {
  const CryptoToolApp({super.key});

  @override
  State<CryptoToolApp> createState() => _CryptoToolAppState();
}

class _CryptoToolAppState extends State<CryptoToolApp> {
  String _output = '';

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _output));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crypto Tool'),
        backgroundColor: Colors.teal.shade900,
      ),
      body: const Center(
        child: Text(
          'Crypto Tool - Coming Soon',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
