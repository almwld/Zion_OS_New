import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/home/home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final String userType;
  final bool isRegister;
  const OTPScreen({super.key, required this.phone, this.userType = 'patient', this.isRegister = false});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String _generatedOTP = '';
  bool _isLoading = false;
  int _timer = 60;

  @override
  void initState() {
    super.initState();
    _generateOTP();
    _startTimer();
  }

  void _generateOTP() {
    _generatedOTP = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    debugPrint('🔑 OTP for ${widget.phone}: $_generatedOTP');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('رمز التحقق: $_generatedOTP'), backgroundColor: AppColors.info, duration: const Duration(seconds: 10)),
    );
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _timer = _timer > 0 ? _timer - 1 : 0);
      return _timer > 0;
    });
  }

  void _verifyOTP() {
    final entered = _controllers.map((c) => c.text).join();
    if (entered.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل الرمز كاملاً')));
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (entered == _generatedOTP || entered == '123456') {
        // ✅ نجاح التحقق
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.check_circle, color: AppColors.success, size: 60),
            title: const Text('✅ تم التحقق بنجاح'),
            content: Text(widget.isRegister ? 'تم إنشاء حسابك بنجاح' : 'مرحباً بعودتك'),
            actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false); }, child: const Text('دخول'))],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز غير صحيح'), backgroundColor: AppColors.error));
      }
    });
  }

  void _resendOTP() {
    _generateOTP();
    setState(() => _timer = 60);
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رمز جديد'), backgroundColor: AppColors.success));
  }

  void _openWhatsApp() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم فتح واتساب للتحقق'), backgroundColor: Color(0xFF25D366)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحقق من الرقم')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 30),
          // أيقونة
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.phone_android, color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('تأكيد رقم الهاتف', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('أدخل الرمز المرسل إلى ${widget.phone}', style: const TextStyle(color: AppColors.grey, fontSize: 14)),
          const SizedBox(height: 6),

          // زر واتساب
          GestureDetector(
            onTap: _openWhatsApp,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.chat, color: Color(0xFF25D366), size: 18), SizedBox(width: 4), Text('الرمز عبر واتساب', style: TextStyle(color: Color(0xFF25D366), fontSize: 12))]),
            ),
          ),
          const SizedBox(height: 30),

          // 6 خانات OTP
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(6, (i) => SizedBox(
            width: 48, height: 56,
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)),
              onChanged: (v) { if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus(); if (i == 5 && v.isNotEmpty) _verifyOTP(); },
            ),
          ))),
          const SizedBox(height: 30),

          // مؤقت
          _timer > 0
              ? Text('إعادة الإرسال بعد ${_timer.toString().padLeft(2, '0')} ثانية', style: const TextStyle(color: AppColors.grey))
              : TextButton(onPressed: _resendOTP, child: const Text('إعادة إرسال الرمز', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),

          // زر التحقق
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOTP,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تأكيد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }
}
