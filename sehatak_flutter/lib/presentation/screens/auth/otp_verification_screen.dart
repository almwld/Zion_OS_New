import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});
  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _fns = List.generate(6, (_) => FocusNode());
  int _timer = 60;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) { if (_timer > 0) { setState(() => _timer--); } else { t.cancel(); } });
  }

  void _verify() {
    final otp = _ctrls.map((c) => c.text).join();
    if (otp.length == 6) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رمز التحقق')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 40),
          const Icon(Icons.verified_user, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text('أدخل رمز التحقق', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('تم إرسال رمز إلى ${widget.phone}', style: const TextStyle(color: AppColors.grey, fontSize: 14)),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(6, (i) => SizedBox(width: 48, height: 56, child: TextField(controller: _ctrls[i], focusNode: _fns[i], textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: InputDecoration(counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), onChanged: (v) { if (v.isNotEmpty && i < 5) _fns[i+1].requestFocus(); if (i == 5 && v.isNotEmpty) _verify(); })))),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _verify, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('تحقق', style: TextStyle(fontSize: 17)))),
          const SizedBox(height: 16),
          TextButton(onPressed: _timer == 0 ? () => setState(() { _timer = 60; _countdown = Timer.periodic(const Duration(seconds: 1), (t) { if (_timer > 0) { setState(() => _timer--); } else { t.cancel(); } }); }) : null, child: Text(_timer > 0 ? 'إعادة الإرسال (${_timer}ث)' : 'إعادة الإرسال', style: TextStyle(color: _timer == 0 ? AppColors.primary : AppColors.grey))),
        ]),
      ),
    );
  }

  @override
  void dispose() { for (var c in _ctrls) c.dispose(); for (var f in _fns) f.dispose(); _countdown?.cancel(); super.dispose(); }
}
