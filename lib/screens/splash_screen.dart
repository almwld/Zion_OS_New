import 'package:flutter/material.dart';
import '../widgets/boot_animation.dart';
import 'lock_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BootAnimation(
      onComplete: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LockScreen()),
        );
      },
    );
  }
}
