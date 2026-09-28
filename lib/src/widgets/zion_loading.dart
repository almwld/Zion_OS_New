import 'package:flutter/material.dart';

class ZionLoading extends StatelessWidget {
  final String? message;

  const ZionLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 40, height: 40, child: CircularProgressIndicator()),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }
}
