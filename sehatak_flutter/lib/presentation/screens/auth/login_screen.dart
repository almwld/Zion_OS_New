import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/core/services/biometric_service.dart';
import 'package:sehatak/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:sehatak/presentation/screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirm = TextEditingController();
  
  bool _obscure = true, _obscure2 = true, _agree = false;
  final BiometricService _bio = BiometricService();
  bool _hasBiometric = false;
  String _bioName = 'البصمة';
  bool _isKeyboardOpen = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _checkBiometric();
    _focusNode.addListener(() {
      setState(() => _isKeyboardOpen = _focusNode.hasFocus);
    });
  }

  Future<void> _checkBiometric() async {
    final available = await _bio.isAvailable();
    if (available) {
      final types = await _bio.getAvailableTypes();
      setState(() { _hasBiometric = true; _bioName = _bio.getBiometricName(types); });
    }
  }

  Future<void> _loginWithBiometric() async {
    final ok = await _bio.authenticate(reason: 'استخدم $_bioName لتسجيل الدخول');
    if (ok && mounted) context.read<AuthBloc>().add(LoginWithEmail(email: 'bio@sehatak.com', password: 'bio'));
  }

  @override
  void dispose() {
    _tabCtrl.dispose(); _email.dispose(); _pass.dispose(); _name.dispose();
    _regEmail.dispose(); _regPhone.dispose(); _regPass.dispose(); _regConfirm.dispose();
    _focusNode.dispose(); super.dispose();
  }

  void _login() {
    if (_email.text.isEmpty || _pass.text.isEmpty) { _showMsg('املأ الحقول', true); return; }
    context.read<AuthBloc>().add(LoginWithEmail(email: _email.text.trim(), password: _pass.text.trim()));
  }

  void _register() {
    if (_name.text.isEmpty || _regEmail.text.isEmpty || _regPass.text.isEmpty) { _showMsg('املأ الحقول', true); return; }
    if (!_agree) { _showMsg('وافق على الشروط', true); return; }
    if (_regPass.text != _regConfirm.text) { _showMsg('كلمتا المرور غير متطابقتين', true); return; }
    if (_regPass.text.length < 6) { _showMsg('6 أحرف على الأقل', true); return; }
    context.read<AuthBloc>().add(RegisterWithEmail(name: _name.text.trim(), email: _regEmail.text.trim(), phone: _regPhone.text.trim(), password: _regPass.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, s) {
        if (s is Authenticated) {
          Navigator.of(ctx).pushAndRemoveUntil(PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)), child: child)),
            transitionDuration: const Duration(milliseconds: 400),
          ), (route) => false);
        }
        if (s is AuthError) _showMsg(s.message, true);
      },
      builder: (ctx, s) => Scaffold(
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: d ? [const Color(0xFF0B1121), const Color(0xFF1A2540)] : AppColors.primaryGradient)),
            child: SafeArea(child: Center(child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  // شعار يختفي عند فتح الكيبورد
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isKeyboardOpen ? 0 : 120,
                    child: _isKeyboardOpen ? const SizedBox.shrink() : Column(children: [
                      const SizedBox(height: 10),
                      Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.health_and_safety, size: 38, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      const Text('صحتك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ]),
                  ),
                  
                  // بصمة - تختفي مع الكيبورد
                  if (_hasBiometric && !_isKeyboardOpen) ...[
                    GestureDetector(
                      onTap: _loginWithBiometric,
                      child: Container(width: 55, height: 55, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Icon(Icons.fingerprint, color: Colors.white, size: 30)),
                    ),
                    const SizedBox(height: 4),
                    Text('تسجيل الدخول بـ $_bioName', style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    const Row(children: [Expanded(child: Divider(color: Colors.white30)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('أو', style: TextStyle(color: Colors.white70))), Expanded(child: Divider(color: Colors.white30))]),
                  ],
                  
                  // Google - يختفي مع الكيبورد
                  if (!_isKeyboardOpen) ...[
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, height: 44, child: OutlinedButton(
                      onPressed: () => context.read<AuthBloc>().add(LoginWithGoogle()),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), backgroundColor: Colors.white.withOpacity(0.1)),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.g_mobiledata, color: Colors.red, size: 22), SizedBox(width: 8), Text('المتابعة بـ Google', style: TextStyle(fontSize: 14, color: Colors.white))]),
                    )),
                    const SizedBox(height: 12),
                  ],
                  
                  // بطاقة تسجيل الدخول
                  Container(
                    decoration: BoxDecoration(color: d ? const Color(0xFF1A2540) : Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      Container(margin: const EdgeInsets.all(14), decoration: BoxDecoration(color: d ? const Color(0xFF0B1121) : Colors.grey[100], borderRadius: BorderRadius.circular(14)), child: TabBar(controller: _tabCtrl, indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)), labelColor: Colors.white, unselectedLabelColor: Colors.grey, padding: const EdgeInsets.all(4), tabs: const [Tab(text: 'تسجيل الدخول'), Tab(text: 'إنشاء حساب')])),
                      SizedBox(height: _tabCtrl.index == 0 ? 240 : 430, child: TabBarView(controller: _tabCtrl, children: [
                        _buildLoginTab(s),
                        _buildRegisterTab(s),
                      ])),
                    ]),
                  ),
                ]),
              ),
            ))),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(AuthState s) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _email, focusNode: _focusNode, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 12),
      TextField(controller: _pass, obscureText: _obscure, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: s is AuthLoading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: s is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16)))),
    ]));
  }

  Widget _buildRegisterTab(AuthState s) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _name, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'الاسم الكامل', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 10),
      TextField(controller: _regEmail, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 10),
      TextField(controller: _regPhone, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'رقم الهاتف', prefixIcon: const Icon(Icons.phone_android), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 10),
      TextField(controller: _regPass, obscureText: _obscure, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 10),
      TextField(controller: _regConfirm, obscureText: _obscure2, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'تأكيد كلمة المرور', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 8),
      Row(children: [Checkbox(value: _agree, activeColor: AppColors.primary, onChanged: (v) => setState(() => _agree = v!)), const Text('أوافق على الشروط', style: TextStyle(fontSize: 11))]),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: s is AuthLoading ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: s is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إنشاء حساب', style: TextStyle(fontSize: 16)))),
    ]));
  }

  void _showMsg(String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : Colors.green, behavior: SnackBarBehavior.floating));
  }
}
