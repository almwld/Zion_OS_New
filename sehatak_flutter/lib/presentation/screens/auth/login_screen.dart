import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sehatak/core/constants/app_colors.dart';
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
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _name = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirm = TextEditingController();
  
  bool _isPhone = false;
  bool _otpSent = false;
  bool _obscure = true;
  bool _obscure2 = true;
  bool _agree = false;
  String _userType = 'patient';
  String _verId = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _email.dispose(); _pass.dispose(); _phone.dispose(); _otp.dispose();
    _name.dispose(); _regEmail.dispose(); _regPhone.dispose();
    _regPass.dispose(); _regConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is Authenticated) {
          Navigator.pushAndRemoveUntil(ctx, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
        }
        if (state is AuthError) _showError(state.message);
        if (state is AuthCodeSent) setState(() { _otpSent = true; _verId = state.verificationId; });
        if (state is PasswordResetSent) _showSuccess('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني');
      },
      builder: (ctx, state) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark 
                  ? [const Color(0xFF0B1121), const Color(0xFF1A2540)]
                  : [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    _buildLogo(),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2540) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(children: [
                        _buildTabs(isDark),
                        _buildUserTypeSelector(isDark),
                        SizedBox(
                          height: _tabCtrl.index == 0 ? (_isPhone && _otpSent ? 300 : 370) : 500,
                          child: TabBarView(
                            controller: _tabCtrl,
                            children: [
                              _buildLoginTab(isDark, state),
                              _buildRegisterTab(isDark, state),
                            ],
                          ),
                        ),
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

  Widget _buildLogo() {
    return Column(children: [
      Container(
        width: 85, height: 85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
        ),
        child: const Icon(Icons.health_and_safety, size: 48, color: AppColors.primary),
      ),
      const SizedBox(height: 14),
      const Text('صحتك', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
      const Text('منصة الرعاية الصحية الشاملة', style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Cairo')),
    ]);
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1121) : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
        padding: const EdgeInsets.all(4),
        tabs: const [Tab(text: 'تسجيل الدخول'), Tab(text: 'إنشاء حساب')],
      ),
    );
  }

  Widget _buildUserTypeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(child: _buildTypeCard('مريض', Icons.person, 'patient', isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildTypeCard('طبيب', Icons.medical_services, 'doctor', isDark)),
      ]),
    );
  }

  Widget _buildTypeCard(String title, IconData icon, String type, bool isDark) {
    final selected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : (isDark ? const Color(0xFF0B1121) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey[300]!, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? AppColors.primary : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: selected ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildLoginTab(bool isDark, AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildChip('الإيميل', !_isPhone),
          const SizedBox(width: 8),
          _buildChip('الهاتف', _isPhone),
        ]),
        const SizedBox(height: 14),
        
        if (_isPhone && !_otpSent) ...[
          _buildPhoneField(isDark),
          const SizedBox(height: 14),
          _buildButton('إرسال رمز التحقق', state, () {
            if (_phone.text.length < 9) { _showError('يرجى إدخال رقم هاتف صحيح'); return; }
            context.read<AuthBloc>().add(LoginWithPhone(_phone.text.trim()));
          }),
        ] else if (_isPhone && _otpSent) ...[
          _buildOtpField(isDark),
          const SizedBox(height: 14),
          _buildButton('تأكيد الرمز', state, () {
            if (_otp.text.length != 6) { _showError('يرجى إدخال رمز التحقق كاملاً'); return; }
            context.read<AuthBloc>().add(VerifyPhoneOTP(verificationId: _verId, otp: _otp.text.trim()));
          }),
          TextButton(onPressed: () => setState(() { _otpSent = false; _otp.clear(); }), child: const Text('تغيير رقم الهاتف', style: TextStyle(fontFamily: 'Cairo'))),
        ] else ...[
          _buildTextField(isDark, _email, 'البريد الإلكتروني', Icons.email_outlined, TextInputType.emailAddress),
          const SizedBox(height: 10),
          _buildPasswordField(isDark, _pass, 'كلمة المرور'),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerLeft, child: TextButton(
            onPressed: () {
              if (_email.text.isEmpty) { _showError('أدخل بريدك الإلكتروني أولاً'); return; }
              context.read<AuthBloc>().add(ResetPassword(_email.text.trim()));
            },
            child: const Text('نسيت كلمة المرور؟', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
          )),
          const SizedBox(height: 6),
          _buildButton('تسجيل الدخول', state, () {
            if (_email.text.isEmpty || _pass.text.isEmpty) { _showError('يرجى إدخال البريد الإلكتروني وكلمة المرور'); return; }
            context.read<AuthBloc>().add(LoginWithEmail(email: _email.text.trim(), password: _pass.text.trim()));
          }),
        ],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('ليس لديك حساب؟', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
          TextButton(onPressed: () => _tabCtrl.animateTo(1), child: const Text('إنشاء حساب', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
        ]),
      ]),
    );
  }

  Widget _buildRegisterTab(bool isDark, AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _buildTextField(isDark, _name, 'الاسم الكامل', Icons.person_outline, TextInputType.text),
        const SizedBox(height: 9),
        _buildTextField(isDark, _regEmail, 'البريد الإلكتروني', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 9),
        _buildTextField(isDark, _regPhone, 'رقم الهاتف', Icons.phone_android, TextInputType.phone),
        const SizedBox(height: 9),
        _buildPasswordField(isDark, _regPass, 'كلمة المرور'),
        const SizedBox(height: 9),
        _buildConfirmPasswordField(isDark, _regConfirm, 'تأكيد كلمة المرور'),
        const SizedBox(height: 8),
        Row(children: [
          Checkbox(value: _agree, activeColor: AppColors.primary, onChanged: (v) => setState(() => _agree = v!), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          const Expanded(child: Text('أوافق على الشروط والأحكام', style: TextStyle(fontSize: 10, fontFamily: 'Cairo'))),
        ]),
        const SizedBox(height: 4),
        _buildButton('إنشاء حساب', state, () {
          if (!_agree) { _showError('يرجى الموافقة على الشروط والأحكام'); return; }
          if (_regPass.text != _regConfirm.text) { _showError('كلمتا المرور غير متطابقتين'); return; }
          if (_regPass.text.length < 6) { _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل'); return; }
          if (_name.text.isEmpty) { _showError('يرجى إدخال الاسم'); return; }
          context.read<AuthBloc>().add(RegisterWithEmail(
            name: _name.text.trim(),
            email: _regEmail.text.trim(),
            phone: _regPhone.text.trim(),
            password: _regPass.text.trim(),
          ));
        }),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('لديك حساب؟', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
          TextButton(onPressed: () => _tabCtrl.animateTo(0), child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'))),
        ]),
      ]),
    );
  }

  // ---------- Widgets ----------
  Widget _buildTextField(bool d, TextEditingController c, String l, IconData i, TextInputType t, {String? hint, String? prefix}) {
    return TextField(
      controller: c, keyboardType: t, textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: l, hintText: hint,
        prefixIcon: Icon(i, size: 20), prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: d ? const Color(0xFF0B1121) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildPasswordField(bool d, TextEditingController c, String l) {
    return TextField(
      controller: c, obscureText: _obscure, textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: l, prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: d ? const Color(0xFF0B1121) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildConfirmPasswordField(bool d, TextEditingController c, String l) {
    return TextField(
      controller: c, obscureText: _obscure2, textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: l, prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _obscure2 = !_obscure2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: d ? const Color(0xFF0B1121) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildPhoneField(bool d) {
    return _buildTextField(d, _phone, 'رقم الهاتف', Icons.phone_android, TextInputType.phone, hint: '770123456', prefix: '+967 ');
  }

  Widget _buildOtpField(bool d) {
    return Column(children: [
      const Icon(Icons.verified_user, size: 45, color: AppColors.primary),
      const SizedBox(height: 8),
      Text('تم إرسال رمز التحقق إلى +967${_phone.text}', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Cairo'), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      TextField(
        controller: _otp, keyboardType: TextInputType.number, maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.bold),
        decoration: InputDecoration(counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: d ? const Color(0xFF0B1121) : Colors.grey[50]),
      ),
    ]);
  }

  Widget _buildButton(String text, AuthState state, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(
        onPressed: state is AuthLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2,
        ),
        child: state is AuthLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildChip(String text, bool selected) {
    return GestureDetector(
      onTap: () => setState(() { _isPhone = text == 'الهاتف'; _otpSent = false; _otp.clear(); }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: TextStyle(color: selected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }
}
