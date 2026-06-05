import 'package:flutter/material.dart';
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

  final List<OnboardingItem> _pages = [
    OnboardingItem(icon: Icons.health_and_safety, title: 'صحتك أولاً', description: 'منصة الرعاية الصحية الشاملة\nاستشر الأطباء واحجز مواعيدك بسهولة', gradient: AppColors.primaryGradient),
    OnboardingItem(icon: Icons.local_pharmacy, title: 'صيدلية متكاملة', description: 'اطلب أدويتك واستلمها لمنزلك\nمع توصيل سريع وآمن', gradient: AppColors.secondaryGradient),
    OnboardingItem(icon: Icons.medical_services, title: 'رعاية متواصلة', description: 'متابعة صحية شاملة وتحاليل مخبرية\nوخدمات طوارئ على مدار الساعة', gradient: AppColors.medicalGradient),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      SharedPreferences.getInstance().then((p) => p.setBool('onboarding_shown', false)).then((_) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
    final colors = _pages[_currentPage].gradient;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors)),
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
        Container(width: 160, height: 160, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]), child: Icon(item.icon, size: 80, color: Colors.white)),
        const SizedBox(height: 50),
        Text(item.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(item.description, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85), height: 1.6, fontFamily: 'Cairo'), textAlign: TextAlign.center),
      ]),
    );
  }
}

class OnboardingItem {
  final IconData icon; final String title; final String description; final List<Color> gradient;
  OnboardingItem({required this.icon, required this.title, required this.description, required this.gradient});
}
