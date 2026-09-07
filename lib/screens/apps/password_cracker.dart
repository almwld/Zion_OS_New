import 'package:flutter/material.dart';

class PasswordCrackerApp extends StatelessWidget {
  const PasswordCrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Security')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64),
              SizedBox(height: 16),
              Text('Password cracking is disabled in the production build.', textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text('Use approved password-audit tooling in an isolated laboratory environment.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
