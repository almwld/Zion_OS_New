import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../security/core/security_core.dart';
import '../security/core/security_event.dart';
import '../security/core/security_result.dart';
import 'desktop_home.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  Timer? _clockTimer;
  String _errorMessage = '';
  String _currentTime = '';
  String _currentDate = '';
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateDateTime();
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    if (!mounted) return;
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate = '${now.day}/${now.month}/${now.year}';
    });
  }

  void _publishLockEvent(String type, String outcome) {
    final core = context.read<SecurityCore>();
    final result = SecurityResult(
      id: 'lock-${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now().toUtc(),
      source: ResultSource.real,
      severity: SecuritySeverity.info,
      title: type,
      description: 'Zion OS lock lifecycle event.',
      confidence: 1,
      metadata: <String, Object?>{'outcome': outcome},
    );
    core.publish(
      SecurityEvent(
        id: result.id,
        timestamp: result.timestamp,
        type: type,
        result: result,
        attributes: <String, Object?>{'outcome': outcome},
      ),
    );
  }

  Future<void> _unlock() async {
    final theme = context.read<ThemeProvider>();
    if (!theme.isReady) return;

    final now = DateTime.now();
    if (_lockedUntil != null && now.isBefore(_lockedUntil!)) {
      final seconds = _lockedUntil!.difference(now).inSeconds + 1;
      setState(() => _errorMessage = 'حاول مرة أخرى بعد $seconds ثانية');
      return;
    }

    final pin = _pinController.text;
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return;

    if (!theme.hasPin) {
      if (await theme.setInitialPin(pin) && mounted) {
        _publishLockEvent('lock.initialized', 'success');
        _openDesktop();
      }
      return;
    }

    if (theme.validatePin(pin)) {
      _failedAttempts = 0;
      _lockedUntil = null;
      _publishLockEvent('lock.unlock', 'success');
      _openDesktop();
      return;
    }

    _failedAttempts++;
    _pinController.clear();
    _publishLockEvent('lock.unlock', 'failure');
    if (_failedAttempts >= 5) {
      _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
      _failedAttempts = 0;
      setState(() => _errorMessage = 'تم إيقاف المحاولات لمدة 30 ثانية');
    } else {
      setState(() => _errorMessage = 'PIN غير صحيح');
    }
  }

  void _openDesktop() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ZionDesktop()),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;
    final foreground = isDark ? Colors.white : const Color(0xFF263238);
    final muted = isDark ? Colors.white70 : Colors.black54;
    final surface = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: isDark
                ? [const Color(0xFF0A2E38), Colors.black]
                : [const Color(0xFFE0F7FA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('Z', style: TextStyle(fontSize: 55, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(_currentTime, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF00BCD4))),
                  const SizedBox(height: 8),
                  Text(_currentDate, style: TextStyle(fontSize: 16, color: muted)),
                  const SizedBox(height: 35),
                  Text(
                    theme.isReady
                        ? (theme.hasPin ? 'أدخل رمز PIN' : 'أنشئ رمز PIN من 4 أرقام')
                        : 'جاري تجهيز الحماية…',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: 280,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.5)),
                    ),
                    child: TextField(
                      controller: _pinController,
                      enabled: theme.isReady,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 24, letterSpacing: 10),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        hintText: '••••',
                        hintStyle: TextStyle(color: muted.withOpacity(0.5)),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _unlock(),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 300,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      children: [
                        _buildButton('1', foreground, surface), _buildButton('2', foreground, surface), _buildButton('3', foreground, surface),
                        _buildButton('4', foreground, surface), _buildButton('5', foreground, surface), _buildButton('6', foreground, surface),
                        _buildButton('7', foreground, surface), _buildButton('8', foreground, surface), _buildButton('9', foreground, surface),
                        _buildButton('', foreground, surface), _buildButton('0', foreground, surface), _buildButton('⌫', foreground, surface),
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

  Widget _buildButton(String num, Color foreground, Color surface) {
    return GestureDetector(
      onTap: () {
        if (num == '⌫') {
          if (_pinController.text.isNotEmpty) {
            _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
          }
        } else if (num.isNotEmpty && _pinController.text.length < 4) {
          _pinController.text += num;
          if (_pinController.text.length == 4) _unlock();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: surface,
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
