import 'package:flutter/material.dart';
import 'desktop_home.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = "1234";
  String _errorMessage = "";
  String _currentTime = "";
  String _currentDate = "";
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _fadeController.forward();
    _updateDateTime();
  }

  void _updateDateTime() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
          _currentDate = "${_getDayName(now.weekday)}, ${now.day} ${_getMonthName(now.month)}";
        });
        _updateDateTime();
      }
    });
  }

  String _getDayName(int weekday) {
    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  void _unlock() async {
    if (_pinController.text == _correctPin) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ZionDesktop()),
        );
      }
    } else {
      setState(() {
        _errorMessage = "INCORRECT PIN";
        _pinController.clear();
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _errorMessage = "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              const Color(0xFF0A2E38),
              const Color(0xFF031217),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF00BCD4)),
                      const SizedBox(height: 16),
                      Text(
                        'UNLOCKING...',
                        style: TextStyle(
                          color: const Color(0xFF00BCD4),
                          fontSize: screenWidth * 0.035,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: screenWidth * 0.22,
                          height: screenWidth * 0.22,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00BCD4).withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Z",
                              style: TextStyle(
                                fontSize: 70,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Title
                        Text(
                          "ZION OS",
                          style: TextStyle(
                            fontSize: screenWidth * 0.09,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "SECURITY SUITE",
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF00BCD4),
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Time
                        Text(
                          _currentTime,
                          style: TextStyle(
                            fontSize: screenWidth * 0.15,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentDate,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 60),
                        // PIN Input
                        Container(
                          width: screenWidth * 0.65,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.5)),
                          ),
                          child: TextField(
                            controller: _pinController,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF00BCD4),
                              fontSize: screenWidth * 0.07,
                              letterSpacing: 12,
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              hintText: "••••",
                              hintStyle: TextStyle(color: Colors.white30, fontSize: 20),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            onSubmitted: (_) => _unlock(),
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red, fontSize: 12, letterSpacing: 1),
                            ),
                          ),
                        const SizedBox(height: 40),
                        // Number Pad
                        Container(
                          width: screenWidth * 0.8,
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 3,
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1.1,
                            children: [
                              _buildNumberButton("1", screenWidth),
                              _buildNumberButton("2", screenWidth),
                              _buildNumberButton("3", screenWidth),
                              _buildNumberButton("4", screenWidth),
                              _buildNumberButton("5", screenWidth),
                              _buildNumberButton("6", screenWidth),
                              _buildNumberButton("7", screenWidth),
                              _buildNumberButton("8", screenWidth),
                              _buildNumberButton("9", screenWidth),
                              _buildNumberButton("", screenWidth),
                              _buildNumberButton("0", screenWidth),
                              _buildDeleteButton(screenWidth),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String num, double screenWidth) {
    return GestureDetector(
      onTap: () {
        if (_pinController.text.length < 4) {
          _pinController.text += num;
          if (_pinController.text.length == 4) _unlock();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            num,
            style: TextStyle(
              color: const Color(0xFF00BCD4),
              fontSize: screenWidth * 0.07,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(double screenWidth) {
    return GestureDetector(
      onTap: () {
        if (_pinController.text.isNotEmpty) {
          _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Center(
          child: Icon(Icons.backspace, color: const Color(0xFF00BCD4), size: screenWidth * 0.07),
        ),
      ),
    );
  }
}
// إضافة تأثير fade للشعار
