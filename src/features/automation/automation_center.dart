import 'package:flutter/material.dart';

class AutomationCenter extends StatelessWidget {
  const AutomationCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Automation Center', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text('Automation Center - قيد التطوير', style: TextStyle(color: Color(0xFF00FF41))),
      ),
    );
  }
}
