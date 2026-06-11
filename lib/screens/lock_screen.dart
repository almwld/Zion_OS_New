import 'package:flutter/material.dart';
import 'desktop_home.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = "1234";
  String _errorMessage = "";
  String _currentTime = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        });
        _updateTime();
      }
    });
  }

  void _unlock() async {
    if (_pinController.text == _correctPin) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ZionDesktop()),
        );
      }
    } else {
      setState(() {
        _errorMessage = "PIN INCORRECT";
        _pinController.clear();
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _errorMessage = "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF0D2E3B), Color(0xFF03090C)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF00BCD4)),
                      SizedBox(height: 16),
                      Text('Loading...', style: TextStyle(color: Color(0xFF00BCD4))),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.5), blurRadius: 30),
                        ],
                      ),
                      child: const Center(
                        child: Text("Z", style: TextStyle(fontSize: 55, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("ZION OS 2027", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00BCD4))),
                    const SizedBox(height: 50),
                    Text(_currentTime, style: const TextStyle(fontSize: 48, color: Color(0xFF00BCD4), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 50),
                    
                    Container(
                      width: 280,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.5)),
                      ),
                      child: TextField(
                        controller: _pinController,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 24, letterSpacing: 10),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          hintText: "••••",
                          hintStyle: TextStyle(color: Colors.white30, fontSize: 24),
                          border: InputBorder.none,
                          counterText: "",
                        ),
                        onSubmitted: (_) => _unlock(),
                      ),
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: 300,
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        children: [
                          _buildButton("1"), _buildButton("2"), _buildButton("3"),
                          _buildButton("4"), _buildButton("5"), _buildButton("6"),
                          _buildButton("7"), _buildButton("8"), _buildButton("9"),
                          _buildButton(""), _buildButton("0"), _buildButton("⌫"),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildButton(String num) {
    return GestureDetector(
      onTap: () {
        if (num == "⌫") {
          if (_pinController.text.isNotEmpty) {
            _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
          }
        } else if (num.isNotEmpty) {
          if (_pinController.text.length < 4) {
            _pinController.text += num;
            if (_pinController.text.length == 4) _unlock();
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Center(
          child: Text(num, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 28, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
