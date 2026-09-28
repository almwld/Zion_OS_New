import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Zion OS',
      description: 'The most advanced mobile penetration testing operating system',
      icon: Icons.security,
      color: Colors.green,
    ),
    OnboardingPage(
      title: '1000+ Tools',
      description: 'Access over 1000 hacking tools right from your phone',
      icon: Icons.build,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'SI Agent',
      description: 'AI-powered autonomous attack agent that learns from every attempt',
      icon: Icons.psychology,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'No Root Required',
      description: 'Works on any Android device without root access',
      icon: Icons.check_circle,
      color: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return _buildPage(page);
              },
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(page.icon, color: page.color, size: 60),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              _pageController.jumpToPage(_pages.length - 1);
            },
            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
          ),
          Row(
            children: List.generate(_pages.length, (index) => Container(
              width: 8, height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? Colors.green : Colors.grey,
              ),
            )),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentPage == _pages.length - 1) {
                Navigator.pushReplacementNamed(context, '/lock');
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
