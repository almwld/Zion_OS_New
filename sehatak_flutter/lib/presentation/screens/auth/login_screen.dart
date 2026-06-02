import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../bloc/auth_bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _otpSent = false;
  String? _devOtp;
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  void _sendOTP() {
    if (_phoneCtrl.text.trim().length >= 9) {
      context.read<AuthBloc>().add(SendOTP(_phoneCtrl.text.trim()));
    }
  }

  void _verifyOTP() {
    if (_otpCtrl.text.trim().length == 6) {
      context.read<AuthBloc>().add(LoginWithOTP(phone: _phoneCtrl.text.trim(), otp: _otpCtrl.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is OTPSent) { setState(() { _otpSent = true; _devOtp = state.devOtp; }); }
        if (state is AuthAuthenticated) Navigator.pushReplacementNamed(ctx, '/home');
        if (state is AuthError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
        setState(() => _loading = state is AuthLoading);
      },
      builder: (ctx, state) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark ? [const Color(0xFF0B1121), const Color(0xFF1A2540)] : [Colors.white, AppColors.surfaceContainerLow],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(children: [
                    const SizedBox(height: 20),

                    // Logo
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.health_and_safety, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text('منصة صحتك', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('الرعاية الصحية في اليمن', style: TextStyle(fontSize: 13, color: AppColors.grey)),

                    const SizedBox(height: 24),

                    // تبويبات
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2540) : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                      ),
                      child: TabBar(
                        controller: _tab,
                        indicator: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.grey,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        padding: const EdgeInsets.all(4),
                        tabs: const [Tab(text: '📱 الهاتف'), Tab(text: '📧 البريد')],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: TabBarView(controller: _tab, children: [
                        _phoneTab(isDark),
                        _emailTab(isDark),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ========== تبويب الهاتف ==========
  Widget _phoneTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('تسجيل الدخول برقم الهاتف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text('سيتم إرسال رمز تحقق إلى هاتفك', style: TextStyle(fontSize: 12, color: AppColors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 24),

        // حقل الهاتف
        Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2540) : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
          child: TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'رقم الهاتف',
              hintText: '777123456',
              prefixIcon: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.phone_android, color: AppColors.primary, size: 20)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // حقل OTP
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: [
            Container(
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2540) : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                decoration: InputDecoration(
                  labelText: 'رمز التحقق',
                  hintText: '6 أرقام',
                  counterText: '',
                  prefixIcon: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lock, color: AppColors.success, size: 20)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            if (_devOtp != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withOpacity(0.2))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  const Text('رمز التحقق: ', style: TextStyle(fontSize: 14)),
                  Text(_devOtp!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.success)),
                ]),
              ),
          ]),
          crossFadeState: _otpSent ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),

        const SizedBox(height: 8),
        if (_otpSent)
          TextButton(onPressed: _sendOTP, child: const Text('إعادة إرسال الرمز')),

        const SizedBox(height: 24),

        // زر
        Container(
          height: 54,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
          child: ElevatedButton(
            onPressed: _loading ? null : (_otpSent ? _verifyOTP : _sendOTP),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: _loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_otpSent ? 'تأكيد الرمز' : 'إرسال رمز التحقق', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 30),
      ]),
    );
  }

  // ========== تبويب الإيميل ==========
  Widget _emailTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('تسجيل الدخول بالإيميل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text('أدخل بريدك وكلمة المرور', style: TextStyle(fontSize: 12, color: AppColors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 24),

        Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2540) : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
          child: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.email_outlined, color: AppColors.info, size: 20)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), filled: true, fillColor: Colors.transparent),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2540) : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
          child: TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20)), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.grey), onPressed: () => setState(() => _obscure = !_obscure)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), filled: true, fillColor: Colors.transparent),
          ),
        ),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => Navigator.pushNamed(context, '/forgot-password'), child: const Text('نسيت كلمة المرور؟'))),

        const SizedBox(height: 20),
        Container(
          height: 54,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.info.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.info, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 30),
      ]),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _animController.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
