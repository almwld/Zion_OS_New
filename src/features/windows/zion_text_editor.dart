import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ZionTextEditor extends StatefulWidget {
  const ZionTextEditor({super.key});

  @override
  State<ZionTextEditor> createState() => _ZionTextEditorState();
}

class _ZionTextEditorState extends State<ZionTextEditor> {
  final TextEditingController _controller = TextEditingController();
  String _currentFile = '';
  bool _isModified = false;

  Future<void> _newFile() async {
    setState(() {
      _controller.clear();
      _currentFile = '';
      _isModified = false;
    });
  }

  Future<void> _saveFile() async {
    if (_currentFile.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      _currentFile = '${dir.path}/untitled.txt';
    }
    final file = File(_currentFile);
    await file.writeAsString(_controller.text);
    setState(() => _isModified = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_currentFile.isEmpty ? 'Untitled' : _currentFile.split('/').last),
        backgroundColor: Colors.pink.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: _newFile,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFile,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (_) => setState(() => _isModified = true),
            ),
          ),
          Container(
            height: 30,
            color: Colors.grey.shade900,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Text('Lines: ${_controller.text.split('\n').length}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 20),
                Text('Chars: ${_controller.text.length}',
                    style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                if (_isModified)
                  const Text('Modified', style: TextStyle(color: Colors.amber)),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
