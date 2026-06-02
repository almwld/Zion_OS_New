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
  
  // متحكمات تسجيل الدخول
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _loginPhone = TextEditingController();
  final _otpCtrl = TextEditingController();
  
  // متحكمات التسجيل
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirmPass = TextEditingController();
  
  // حالة OTP
  bool _otpSent = false;
  String _devOtp = '';
  String _verificationId = '';
  
  // نوع المستخدم
  String _userType = 'patient'; // patient أو doctor
  
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _isLoginWithPhone = false;

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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ========== الشعار ==========
                      _buildLogo(isDark),
                      const SizedBox(height: 30),
                      
                      // ========== البطاقة الرئيسية ==========
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A2540) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(children: [
                          // ========== التبويبات ==========
                          _buildTabs(isDark),
                          
                          // ========== اختيار نوع المستخدم ==========
                          _buildUserTypeSelector(isDark),
                          
                          // ========== المحتوى ==========
                          SizedBox(
                            height: _tabController.index == 0 ? 380 : 520,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== الشعار ====================
  Widget _buildLogo(bool isDark) {
    return Column(children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)],
        ),
        child: const Icon(Icons.health_and_safety, size: 50, color: AppColors.primary),
      ),
      const SizedBox(height: 15),
      const Text('صحتك', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
      const Text('منصة الرعاية الصحية الشاملة', style: TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'Cairo')),
    ]);
  }

  // ==================== التبويبات ====================
  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1121) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo'),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'تسجيل الدخول'),
          Tab(text: 'إنشاء حساب'),
        ],
      ),
    );
  }

  // ==================== اختيار نوع المستخدم ====================
  Widget _buildUserTypeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
          child: _buildTypeCard('مريض', Icons.person, 'patient', isDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeCard('طبيب', Icons.medical_services, 'doctor', isDark),
        ),
      ]),
    );
  }

  Widget _buildTypeCard(String title, IconData icon, String type, bool isDark) {
    final selected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected 
            ? AppColors.primary.withOpacity(0.1)
            : (isDark ? const Color(0xFF0B1121) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey[300]!, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? AppColors.primary : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: selected ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ]),
      ),
    );
  }

  // ==================== تبويب تسجيل الدخول ====================
  Widget _buildLoginTab(bool isDark, AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // تبديل بين الإيميل والهاتف
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildMethodBtn('الإيميل', !_isLoginWithPhone),
          const SizedBox(width: 8),
          _buildMethodBtn('الهاتف', _isLoginWithPhone),
        ]),
        const SizedBox(height: 16),
        
        if (_isLoginWithPhone && !_otpSent) ...[
          // ========== إدخال الهاتف ==========
          TextField(
            controller: _loginPhone,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'رقم الهاتف',
              hintText: '770123456',
              prefixIcon: const Icon(Icons.phone_android),
              prefixText: '+967 ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            onPressed: state is AuthLoading ? null : () {
              context.read<AuthBloc>().add(LoginWithPhone(_loginPhone.text.trim()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: state is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال رمز التحقق', style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
          )),
        ] else if (_isLoginWithPhone && _otpSent) ...[
          // ========== إدخال OTP ==========
          const Icon(Icons.verified_user, size: 50, color: AppColors.primary),
          const SizedBox(height: 8),
          const Text('أدخل رمز التحقق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
          Text('تم الإرسال إلى +967${_loginPhone.text}', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontFamily: 'Cairo')),
          const SizedBox(height: 16),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            onPressed: state is AuthLoading ? null : () {
              context.read<AuthBloc>().add(VerifyPhoneOTP(verificationId: _verificationId, otp: _otpCtrl.text.trim()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: state is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تحقق', style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
          )),
          TextButton(onPressed: () => setState(() => _otpSent = false), child: const Text('تغيير رقم الهاتف')),
        ] else ...[
          // ========== تسجيل بالإيميل ==========
          TextField(
            controller: _loginEmail,
            keyboardType: TextInputType.emailAddress,
            textAlign: TextAlign.right,
            decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50]),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _loginPass,
            obscureText: _obscurePass,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePass = !_obscurePass)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50],
            ),
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () {}, child: const Text('نسيت كلمة المرور؟'))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            onPressed: state is AuthLoading ? null : () => context.read<AuthBloc>().add(LoginWithEmail(email: _loginEmail.text.trim(), password: _loginPass.text.trim())),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: state is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
          )),
        ],
      ]),
    );
  }

  // ==================== تبويب التسجيل ====================
  Widget _buildRegisterTab(bool isDark, AuthState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(controller: _regName, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'الاسم الكامل', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50])),
        const SizedBox(height: 12),
        TextField(controller: _regEmail, keyboardType: TextInputType.emailAddress, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50])),
        const SizedBox(height: 12),
        TextField(controller: _regPhone, keyboardType: TextInputType.phone, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'رقم الهاتف', prefixIcon: const Icon(Icons.phone_android), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50])),
        const SizedBox(height: 12),
        TextField(controller: _regPass, obscureText: _obscurePass, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePass = !_obscurePass)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50])),
        const SizedBox(height: 12),
        TextField(controller: _regConfirmPass, obscureText: _obscureConfirm, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'تأكيد كلمة المرور', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: isDark ? const Color(0xFF0B1121) : Colors.grey[50])),
        const SizedBox(height: 12),
        Row(children: [
          Checkbox(value: _agreeTerms, activeColor: AppColors.primary, onChanged: (v) => setState(() => _agreeTerms = v!)),
          const Expanded(child: Text('أوافق على الشروط والأحكام', style: TextStyle(fontSize: 12, fontFamily: 'Cairo'))),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: (_agreeTerms && state is! AuthLoading) ? () {
            context.read<AuthBloc>().add(RegisterWithEmail(name: _regName.text.trim(), email: _regEmail.text.trim(), phone: _regPhone.text.trim(), password: _regPass.text.trim()));
          } : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: state is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إنشاء حساب', style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
        )),
      ]),
    );
  }

  Widget _buildMethodBtn(String text, bool selected) {
    return GestureDetector(
      onTap: () => setState(() { _isLoginWithPhone = text == 'الهاتف'; _otpSent = false; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: TextStyle(color: selected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }
}
