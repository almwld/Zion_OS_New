import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CryptoToolApp extends StatefulWidget {
  const CryptoToolApp({super.key});
  @override
  State<CryptoToolApp> createState() => _CryptoToolAppState();
}

class _CryptoToolAppState extends State<CryptoToolApp> {
  final _input = TextEditingController();
  String _output = '';
  String _algorithm = 'SHA-256';
  bool _hexInput = false;

  @override
  void dispose() { _input.dispose(); super.dispose(); }

  void _calculate() {
    try {
      final raw = _hexInput ? _decodeHex(_input.text.trim()) : utf8.encode(_input.text);
      final digest = switch (_algorithm) {
        'MD5' => md5.convert(raw),
        'SHA-1' => sha1.convert(raw),
        'SHA-256' => sha256.convert(raw),
        'SHA-512' => sha512.convert(raw),
        _ => sha256.convert(raw),
      };
      setState(() => _output = digest.toString());
    } catch (e) {
      setState(() => _output = 'Error: $e');
    }
  }

  Uint8List _decodeHex(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '');
    if (normalized.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(normalized)) {
      throw const FormatException('Invalid hexadecimal input');
    }
    return Uint8List.fromList([
      for (var i = 0; i < normalized.length; i += 2)
        int.parse(normalized.substring(i, i + 2), radix: 16),
    ]);
  }

  Future<void> _copyToClipboard() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digest copied to clipboard')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Crypto Tool'), backgroundColor: Colors.teal.shade900),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Cryptographic hash calculator', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _algorithm,
            dropdownColor: Colors.grey.shade900,
            decoration: const InputDecoration(labelText: 'Algorithm', labelStyle: TextStyle(color: Colors.tealAccent), border: OutlineInputBorder()),
            items: const ['MD5', 'SHA-1', 'SHA-256', 'SHA-512'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: TextStyle(color: Colors.white)))).toList(),
            onChanged: (v) => setState(() => _algorithm = v ?? _algorithm),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Input is hexadecimal', style: TextStyle(color: Colors.white)),
            value: _hexInput,
            onChanged: (v) => setState(() => _hexInput = v),
          ),
          TextField(
            controller: _input,
            minLines: 5,
            maxLines: 10,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Enter text or hexadecimal bytes', hintStyle: TextStyle(color: Colors.white38), border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate), label: const Text('Calculate hash')),
          const SizedBox(height: 16),
          if (_output.isNotEmpty)
            Card(
              color: Colors.white10,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: SelectableText(_output, style: const TextStyle(color: Colors.tealAccent, fontFamily: 'monospace'))),
                    IconButton(onPressed: _copyToClipboard, icon: const Icon(Icons.copy, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text('Hashes are one-way digests; this tool does not decrypt passwords or bypass authentication.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
