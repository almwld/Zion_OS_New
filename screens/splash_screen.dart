import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockScreen()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: isDark ? [const Color(0xFF0A2E38), Colors.black] : [const Color(0xFFE0F7FA), Colors.white],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.5), blurRadius: 30)],
                  ),
                  child: const Center(child: Text("Z", style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
                const SizedBox(height: 20),
                const Text("ZION OS", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00BCD4), letterSpacing: 4)),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Color(0xFF00BCD4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
