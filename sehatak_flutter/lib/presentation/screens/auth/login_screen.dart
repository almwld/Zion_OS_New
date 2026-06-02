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
  late TabController _tabController;
  
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _loginPhone = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirmPass = TextEditingController();
  
  bool _otpSent = false;
  String _verificationId = '';
  String _userType = 'patient';
  bool _isLoginWithPhone = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose(); _loginPass.dispose(); _loginPhone.dispose();
    _otpCtrl.dispose(); _regName.dispose(); _regEmail.dispose();
    _regPhone.dispose(); _regPass.dispose(); _regConfirmPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
        } else if (state is AuthError) {
          _showError(state.message);
        } else if (state is AuthCodeSent) {
          setState(() {
            _otpSent = true;
            _verificationId = state.verificationId;
          });
        }
      },
      builder: (context, state) {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const SizedBox(height: 20),
                  _buildLogo(),
                  const SizedBox(height: 25),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2540) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(children: [
                      _buildTabs(isDark),
                      _buildUserTypeSelector(isDark),
                      SizedBox(
                        height: _tabController.index == 0 ? (_isLoginWithPhone && _otpSent ? 300 : 380) : 520,
                        child: TabBarView(
                          controller: _tabController,
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
        );
      },
    );
  }

  Widget _buildLogo() {
    return Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)]),
        child: const Icon(Icons.health_and_safety, size: 45, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      const Text('صحتك', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
      const Text('منصة الرعاية الصحية', style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Cairo')),
    ]);
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0B1121) : Colors.grey[100], borderRadius: BorderRadius.circular(14)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(12)),
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
        Expanded(child: _typeCard('👤 مريض', Icons.person, 'patient', isDark)),
        const SizedBox(width: 10),
        Expanded(child: _typeCard('👨‍⚕️ طبيب', Icons.medical_services, 'doctor', isDark)),
      ]),
    );
  }

  Widget _typeCard(String title, IconData icon, String type, bool isDark) {
    final sel = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withOpacity(0.1) : (isDark ? const Color(0xFF0B1121) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.primary : Colors.grey[300]!, width: sel ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? AppColors.primary : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: sel ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 12)),
        ]),
      ),
    );
  }

  // ==================== LOGIN TAB ====================
  Widget _buildLoginTab(bool isDark, AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _methodBtn('📧 الإيميل', !_isLoginWithPhone),
          const SizedBox(width: 8),
          _methodBtn('📱 الهاتف', _isLoginWithPhone),
        ]),
        const SizedBox(height: 16),
        
        if (_isLoginWithPhone && !_otpSent) ...[
          _phoneField(isDark),
          const SizedBox(height: 16),
          _btn('إرسال رمز التحقق', state, () => context.read<AuthBloc>().add(LoginWithPhone(_loginPhone.text.trim()))),
        ] else if (_isLoginWithPhone && _otpSent) ...[
          _otpField(isDark),
          const SizedBox(height: 16),
          _btn('تأكيد', state, () => context.read<AuthBloc>().add(VerifyPhoneOTP(verificationId: _verificationId, otp: _otpCtrl.text.trim()))),
          TextButton(onPressed: () => setState(() { _otpSent = false; _otpCtrl.clear(); }), child: const Text('تغيير الرقم')),
        ] else ...[
          _textField(isDark, _loginEmail, 'البريد الإلكتروني', Icons.email_outlined, TextInputType.emailAddress),
          const SizedBox(height: 12),
          _passField(isDark, _loginPass, 'كلمة المرور'),
          const SizedBox(height: 4),
          Row(children: [
            Row(children: [
              Checkbox(value: _rememberMe, activeColor: AppColors.primary, onChanged: (v) => setState(() => _rememberMe = v!), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              const Text('تذكرني', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
            ]),
            const Spacer(),
            TextButton(onPressed: () => context.read<AuthBloc>().add(ResetPassword(_loginEmail.text.trim())), child: const Text('نسيت كلمة المرور؟', style: TextStyle(fontSize: 11))),
          ]),
          const SizedBox(height: 4),
          _btn('تسجيل الدخول', state, () => context.read<AuthBloc>().add(LoginWithEmail(email: _loginEmail.text.trim(), password: _loginPass.text.trim()))),
        ],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('ليس لديك حساب؟', style: TextStyle(fontSize: 12, fontFamily: 'Cairo')),
          TextButton(onPressed: () => _tabController.animateTo(1), child: const Text('إنشاء حساب', style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
      ]),
    );
  }

  // ==================== REGISTER TAB ====================
  Widget _buildRegisterTab(bool isDark, AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _textField(isDark, _regName, 'الاسم الكامل', Icons.person_outline, TextInputType.text),
        const SizedBox(height: 10),
        _textField(isDark, _regEmail, 'البريد الإلكتروني', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 10),
        _textField(isDark, _regPhone, 'رقم الهاتف', Icons.phone_android, TextInputType.phone),
        const SizedBox(height: 10),
        _passField(isDark, _regPass, 'كلمة المرور'),
        const SizedBox(height: 10),
        _passFieldConfirm(isDark, _regConfirmPass, 'تأكيد كلمة المرور'),
        const SizedBox(height: 8),
        Row(children: [
          Checkbox(value: _agreeTerms, activeColor: AppColors.primary, onChanged: (v) => setState(() => _agreeTerms = v!), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          const Expanded(child: Text('أوافق على الشروط والأحكام', style: TextStyle(fontSize: 10, fontFamily: 'Cairo'))),
        ]),
        const SizedBox(height: 4),
        _btn('إنشاء حساب', state, () {
          if (!_agreeTerms) { _showError('يرجى الموافقة على الشروط'); return; }
          if (_regPass.text != _regConfirmPass.text) { _showError('كلمتا المرور غير متطابقتين'); return; }
          if (_regPass.text.length < 6) { _showError('كلمة المرور 6 أحرف على الأقل'); return; }
          context.read<AuthBloc>().add(RegisterWithEmail(
            name: _regName.text.trim(),
            email: _regEmail.text.trim(),
            phone: _regPhone.text.trim(),
            password: _regPass.text.trim(),
          ));
        }),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('لديك حساب؟', style: TextStyle(fontSize: 12, fontFamily: 'Cairo')),
          TextButton(onPressed: () => _tabController.animateTo(0), child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold))),
        ]),
      ]),
    );
  }

  // ==================== WIDGETS ====================
  Widget _textField(bool isDark, TextEditingController ctrl, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: ctrl, keyboardType: type, textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _passField(bool isDark, TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl, obscureText: _obscurePass, textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label, prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _obscurePass = !_obscurePass)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _passFieldConfirm(bool isDark, TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl, obscureText: _obscureConfirm, textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label, prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _phoneField(bool isDark) {
    return TextField(
      controller: _loginPhone, keyboardType: TextInputType.phone, textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: 'رقم الهاتف', hintText: '770123456',
        prefixIcon: const Icon(Icons.phone_android, size: 20), prefixText: '+967 ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _phoneFieldReg(bool isDark) => _phoneField(isDark);

  Widget _otpField(bool isDark) {
    return Column(children: [
      const Icon(Icons.verified_user, size: 45, color: AppColors.primary),
      const SizedBox(height: 8),
      Text('رمز التحقق المرسل إلى +967${_loginPhone.text}', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Cairo'), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      TextField(
        controller: _otpCtrl, keyboardType: TextInputType.number, maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.bold),
        decoration: InputDecoration(counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50]),
      ),
    ]);
  }

  Widget _btn(String text, AuthState state, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(
        onPressed: state is AuthLoading ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
        child: state is AuthLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _methodBtn(String text, bool selected) {
    return GestureDetector(
      onTap: () => setState(() { _isLoginWithPhone = text.contains('هاتف'); _otpSent = false; _otpCtrl.clear(); }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.grey[300], borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: selected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }
}
