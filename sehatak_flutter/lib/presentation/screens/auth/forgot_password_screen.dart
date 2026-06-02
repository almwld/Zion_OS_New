import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  void _sendOTP() {
    if (_phoneCtrl.text.isNotEmpty) {
      setState(() => _loading = true);
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _loading = false);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OtpVerificationScreen(phone: '')));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نسيت كلمة المرور')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 40),
          const Icon(Icons.lock_reset, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text('نسيت كلمة المرور', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('أدخل رقم هاتفك لإرسال رمز التحقق', style: TextStyle(color: AppColors.grey, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: 'رقم الهاتف', prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 24),
          SizedBox(height: 52, child: ElevatedButton(onPressed: _loading ? null : _sendOTP, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال رمز التحقق', style: TextStyle(fontSize: 17)))),
        ]),
      ),
    );
  }

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }
}
