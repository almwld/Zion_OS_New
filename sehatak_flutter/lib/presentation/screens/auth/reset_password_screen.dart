import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('كلمة مرور جديدة')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 40),
          const Icon(Icons.lock, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text('أدخل كلمة المرور الجديدة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(controller: _passCtrl, obscureText: _obscure, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'كلمة المرور الجديدة', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 14),
          TextField(controller: _confirmCtrl, obscureText: _obscure, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'تأكيد كلمة المرور', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/home'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('حفظ', style: TextStyle(fontSize: 17)))),
        ]),
      ),
    );
  }

  @override
  void dispose() { _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }
}
