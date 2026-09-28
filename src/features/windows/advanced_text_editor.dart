import 'package:flutter/material.dart';

class AdvancedTextEditor extends StatefulWidget {
  const AdvancedTextEditor({super.key});

  @override
  State<AdvancedTextEditor> createState() => _AdvancedTextEditorState();
}

class _AdvancedTextEditorState extends State<AdvancedTextEditor> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Text Editor', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _textController,
          maxLines: null,
          expands: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'اكتب نصك هنا...',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41), width: 2)),
          ),
        ),
      ),
    );
  }
}
