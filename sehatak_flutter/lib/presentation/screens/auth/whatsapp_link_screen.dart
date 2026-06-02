import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/home/home_screen.dart';

class WhatsAppLinkScreen extends StatefulWidget {
  final String userType;
  const WhatsAppLinkScreen({super.key, this.userType = 'patient'});
  @override
  State<WhatsAppLinkScreen> createState() => _WhatsAppLinkScreenState();
}

class _WhatsAppLinkScreenState extends State<WhatsAppLinkScreen> {
  final _phone = TextEditingController(text: '+967');
  bool _loading = false;

  void _verify() {
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ربط واتساب'), backgroundColor: const Color(0xFF075E54)),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const SizedBox(height: 40), const Icon(Icons.chat, color: Color(0xFF25D366), size: 80),
        const SizedBox(height: 20), const Text('أدخل رقم الواتساب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _phone, keyboardType: TextInputType.phone, textAlign: TextAlign.right, style: const TextStyle(fontSize: 20), decoration: InputDecoration(hintText: '+967 777 123 456', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: _loading ? null : _verify, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('تحقق', style: TextStyle(fontSize: 18, color: Colors.white)))),
      ])),
    );
  }
}
