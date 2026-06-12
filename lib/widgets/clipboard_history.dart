import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ClipboardHistory extends StatefulWidget {
  const ClipboardHistory({super.key});

  @override
  State<ClipboardHistory> createState() => _ClipboardHistoryState();
}

class _ClipboardHistoryState extends State<ClipboardHistory> {
  List<String> _history = [];
  String _currentClipboard = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _startMonitoring();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('clipboard_history');
    if (historyJson != null) {
      try {
        _history = List<String>.from(jsonDecode(historyJson));
      } catch (_) {}
    }
    setState(() {});
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clipboard_history', jsonEncode(_history));
  }

  void _startMonitoring() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      final clipboard = await Clipboard.getData('text/plain');
      final text = clipboard?.text ?? '';
      if (text.isNotEmpty && text != _currentClipboard) {
        setState(() {
          _currentClipboard = text;
          _history.insert(0, text);
          if (_history.length > 20) _history.removeLast();
        });
        _saveHistory();
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), backgroundColor: Color(0xFF00BCD4)),
    );
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
      _saveHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Clipboard History', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Color(0xFF00BCD4)),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: _history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.content_copy, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('No clipboard history', style: TextStyle(color: Colors.white38)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final text = _history[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          text.length > 100 ? '${text.substring(0, 100)}...' : text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFF00BCD4), size: 18),
                        onPressed: () => _copyToClipboard(text),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
