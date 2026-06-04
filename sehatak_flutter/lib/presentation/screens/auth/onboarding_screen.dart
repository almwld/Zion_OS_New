import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  // Lottie URLs مجانية من الإنترنت
  final List<OnboardingItem> _pages = [
    OnboardingItem(
      lottieUrl: 'https://lottie.host/8b2c8e1a-7d4f-4c3e-9a1b-2f5e6d8c0a3f/BCqKZPqW1Z.json',
      fallbackIcon: Icons.health_and_safety,
      title: 'صحتك أولاً',
      description: 'منصة الرعاية الصحية الشاملة\nاستشر الأطباء واحجز مواعيدك بسهولة',
      gradient: AppColors.primaryGradient,
    ),
    OnboardingItem(
      lottieUrl: 'https://lottie.host/9c3d1f2b-8e5a-4d7c-0b2f-3a6e9d1c4b5f/XYzABcDeFg.json',
      fallbackIcon: Icons.local_pharmacy,
      title: 'صيدلية متكاملة',
      description: 'اطلب أدويتك واستلمها لمنزلك\nمع توصيل سريع وآمن',
      gradient: AppColors.secondaryGradient,
    ),
    OnboardingItem(
      lottieUrl: 'https://lottie.host/0a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d/HiJkLmNoPq.json',
      fallbackIcon: Icons.medical_services,
      title: 'رعاية متواصلة',
      description: 'متابعة صحية شاملة وتحاليل مخبرية\nوخدمات طوارئ على مدار الساعة',
      gradient: AppColors.medicalGradient,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      SharedPreferences.getInstance().then((p) => p.setBool('onboarding_shown', false)).then((_) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      });
    }
  }

  void _skip() {
    SharedPreferences.getInstance().then((p) => p.setBool('onboarding_shown', false)).then((_) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _pages[_currentPage].gradient;
    
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: isDark ? AppColors.primaryGradient.map((c) => c.withOpacity(0.3)).toList() : colors,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (_currentPage + 1) / _pages.length, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 4))),
                const SizedBox(width: 12),
                Text('${_currentPage + 1}/${_pages.length}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
              ]),
            ),
            Align(alignment: Alignment.topLeft, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(onPressed: _skip, child: Text('تخطي', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontFamily: 'Cairo'))),
            )),
            Expanded(child: PageView.builder(
              controller: _pageCtrl, onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _pages.length, itemBuilder: (_, i) => _buildPage(_pages[i]),
            )),
            Padding(padding: const EdgeInsets.all(32), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pages.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), width: _currentPage == i ? 28 : 8, height: 8, decoration: BoxDecoration(color: _currentPage == i ? Colors.white : Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(4))))),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: colors[0], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: Text(_currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'التالي', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              )),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0), duration: const Duration(milliseconds: 600),
          builder: (_, val, child) => Transform.scale(scale: val, child: child),
          child: SizedBox(
            width: 200, height: 200,
            child: Icon(
              item.lottieUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 140, height: 140,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
                child: Icon(item.fallbackIcon, size: 70, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(item.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(item.description, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85), height: 1.6, fontFamily: 'Cairo'), textAlign: TextAlign.center),
      ]),
    );
  }
}

class OnboardingItem {
  final String lottieUrl;
  final IconData fallbackIcon;
  final String title;
  final String description;
  final List<Color> gradient;

  OnboardingItem({required this.lottieUrl, required this.fallbackIcon, required this.title, required this.description, required this.gradient});
}
