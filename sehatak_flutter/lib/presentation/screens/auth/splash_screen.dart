import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_bloc/auth_bloc.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => AuthBloc(),
            child: const HomeScreen(), // 👈 HOME بدل LOGIN
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.teal.shade600, Colors.teal.shade800],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text('منصة صحتك', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 8),
              Text('منصتك الطبية المتكاملة', style: TextStyle(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 30),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
