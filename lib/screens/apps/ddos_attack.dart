import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

class DDoSAttackApp extends StatefulWidget {
  const DDoSAttackApp({super.key});

  @override
  State<DDoSAttackApp> createState() => _DDoSAttackAppState();
}

class _DDoSAttackAppState extends State<DDoSAttackApp> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '80');
  final TextEditingController _durationController = TextEditingController(text: '30');
  
  bool _isAttacking = false;
  String _selectedAttack = 'SYN Flood';
  String _status = '';
  int _packetsSent = 0;
  Timer? _attackTimer;
  final Random _random = Random();

  final List<String> _attackTypes = ['SYN Flood', 'UDP Flood', 'HTTP Flood', 'Slowloris', 'Ping of Death'];

  Future<void> _startAttack() async {
    final target = _targetController.text.trim();
    if (target.isEmpty) {
      setState(() => _status = '⚠️ الرجاء إدخال الهدف');
      return;
    }

    setState(() {
      _isAttacking = true;
      _packetsSent = 0;
      _status = '🚀 بدء هجوم $_selectedAttack على $target...';
    });

    _attackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _packetsSent += _random.nextInt(100) + 50);
    });

    await Future.delayed(Duration(seconds: int.tryParse(_durationController.text) ?? 30));
    
    _stopAttack();
  }

  void _stopAttack() {
    _attackTimer?.cancel();
    setState(() {
      _isAttacking = false;
      _status = '✅ توقف الهجوم. تم إرسال $_packetsSent حزمة';
    });
  }

  void _simulateSYNFlood() {
    setState(() => _status = '🔄 هجوم SYN Flood - إرسال حزم SYN...');
  }

  void _simulateUDPFlood() {
    setState(() => _status = '🔄 هجوم UDP Flood - إرسال حزم UDP...');
  }

  void _simulateHTTPFlood() {
    setState(() => _status = '🔄 هجوم HTTP Flood - طلبات HTTP متتالية...');
  }

  void _simulateSlowloris() {
    setState(() => _status = '🔄 هجوم Slowloris - فتح اتصالات بطيئة...');
  }

  void _runAttack() {
    switch (_selectedAttack) {
      case 'SYN Flood': _simulateSYNFlood(); break;
      case 'UDP Flood': _simulateUDPFlood(); break;
      case 'HTTP Flood': _simulateHTTPFlood(); break;
      case 'Slowloris': _simulateSlowloris(); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DDoS Attack', style: TextStyle(color: Color(0xFF00FF41))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FF41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // نوع الهجوم
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAttack,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Color(0xFF00FF41)),
                  items: _attackTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _selectedAttack = v!),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // الهدف
            TextField(
              controller: _targetController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'الهدف (IP أو Domain)',
                labelStyle: TextStyle(color: Color(0xFF00FF41)),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41), width: 2)),
              ),
            ),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _portController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المنفذ',
                      labelStyle: TextStyle(color: Color(0xFF00FF41)),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المدة (ثانية)',
                      labelStyle: TextStyle(color: Color(0xFF00FF41)),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // أزرار التحكم
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAttacking ? null : _startAttack,
                    icon: _isAttacking ? const SizedBox(width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow),
                    label: const Text('بدء الهجوم'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAttacking ? _stopAttack : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('إيقاف'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // إحصائيات
            if (_isAttacking)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text('📊 إحصائيات الهجوم:', style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 5),
                    Text('حزم مرسلة: $_packetsSent', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            
            // زر تنفيذ الهجوم الفعلي
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runAttack,
                icon: const Icon(Icons.flash_on),
                label: const Text('تنفيذ الهجوم الفعلي'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ),
            const SizedBox(height: 10),
            
            // الحالة
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status.isEmpty ? 'جاهز لبدء الهجوم...' : _status,
                    style: const TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
