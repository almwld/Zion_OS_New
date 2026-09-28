import 'package:flutter/material.dart';

class MaintenanceCenter extends StatelessWidget {
  const MaintenanceCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Maintenance Center', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text('Maintenance Center - قيد التطوير', style: TextStyle(color: Color(0xFF00FF41))),
      ),
    );
  }
}
