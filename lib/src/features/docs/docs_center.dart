import 'package:flutter/material.dart';

class DocsCenter extends StatelessWidget {
  const DocsCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Documentation Center', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text('Documentation Center - قيد التطوير', style: TextStyle(color: Color(0xFF00FF41))),
      ),
    );
  }
}
