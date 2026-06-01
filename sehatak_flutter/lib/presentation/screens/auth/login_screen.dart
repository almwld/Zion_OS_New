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
  bool _obscurePassword = true;
  bool _agreeTerms = false;

  final _emailController = TextEditingController(text: 'test@sehatak.com');
  final _passwordController = TextEditingController(text: '123456');
  final _nameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _handleLogin() {
    context.read<AuthBloc>().add(LoginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    ));
  }

  void _handleRegister() {
    context.read<AuthBloc>().add(RegisterWithEmail(
      name: _nameController.text.trim(),
      email: _regEmailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _regPasswordController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            const SizedBox(height: 20),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.health_and_safety, color: Colors.white, size: 45),
            ),
            const Text('صحتك', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: const [Tab(text: 'تسجيل الدخول'), Tab(text: 'إنشاء حساب')],
              ),
            ),
            Expanded(
              child: TabBarView(controller: _tabController, children: [
                _buildLoginTab(),
                _buildRegisterTab(),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        TextField(controller: _emailController, decoration: InputDecoration(labelText: 'الإيميل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 14),
        TextField(controller: _passwordController, obscureText: _obscurePassword, decoration: InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 24),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state is AuthLoading ? null : _handleLogin,
              child: state is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('تسجيل الدخول'),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        TextField(controller: _nameController, decoration: InputDecoration(labelText: 'الاسم', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 14),
        TextField(controller: _regEmailController, decoration: InputDecoration(labelText: 'الإيميل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 14),
        TextField(controller: _phoneController, decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 14),
        TextField(controller: _regPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 24),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state is AuthLoading ? null : _handleRegister,
              child: state is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إنشاء حساب'),
            ),
          ),
        ),
      ]),
    );
  }
}
