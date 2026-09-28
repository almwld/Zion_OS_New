import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class DatabaseHackingApp extends StatefulWidget {
  const DatabaseHackingApp({super.key});

  @override
  State<DatabaseHackingApp> createState() => _DatabaseHackingAppState();
}

class _DatabaseHackingAppState extends State<DatabaseHackingApp> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _wordlistController = TextEditingController();
  String _result = '';
  bool _isAttacking = false;
  String _selectedDB = 'MySQL';
  String _selectedAttack = 'Brute Force';

  final List<String> _databases = ['MySQL', 'PostgreSQL', 'MongoDB', 'Redis'];
  final List<String> _attacks = ['Brute Force', 'Dictionary', 'SQL Injection'];

  Future<void> _bruteForce() async {
    setState(() {
      _isAttacking = true;
      _result = 'جاري هجوم Brute Force على ${_targetController.text}...';
    });

    final users = _userController.text.isNotEmpty ? [_userController.text] : ['root', 'admin', 'test'];
    final passwords = ['', 'root', 'password', '123456', 'admin', 'toor', 'test'];

    for (final user in users) {
      for (final pass in passwords) {
        if (!mounted) return;
        setState(() => _result = 'محاولة: $user : $pass');
        await Future.delayed(const Duration(milliseconds: 100));
        
        // محاكاة نجاح
        if (user == 'root' && pass == '') {
          setState(() {
            _result = '✅ تم اختراق قاعدة البيانات!\nالمستخدم: $user\nكلمة المرور: [فارغة]';
            _isAttacking = false;
          });
          return;
        }
      }
    }

    setState(() {
      _result = '❌ فشل اختراق قاعدة البيانات\nحاول باستخدام قاموس أكبر';
      _isAttacking = false;
    });
  }

  Future<void> _dictionaryAttack() async {
    setState(() {
      _isAttacking = true;
      _result = 'جاري هجوم القاموس...';
    });

    final dict = _wordlistController.text.isNotEmpty 
        ? _wordlistController.text.split(',') 
        : ['root:', 'admin:admin', 'root:toor', 'test:test'];

    for (final entry in dict) {
      if (!mounted) return;
      final parts = entry.split(':');
      final user = parts[0];
      final pass = parts.length > 1 ? parts[1] : '';
      
      setState(() => _result = 'محاولة: $user : $pass');
      await Future.delayed(const Duration(milliseconds: 80));
      
      if (user == 'root' && pass.isEmpty) {
        setState(() {
          _result = '✅ تم الاختراق!\nالمستخدم: root\nكلمة المرور: [فارغة]';
          _isAttacking = false;
        });
        return;
      }
    }

    setState(() {
      _result = '❌ فشل الاختراق';
      _isAttacking = false;
    });
  }

  Future<void> _sqlInjection() async {
    setState(() {
      _isAttacking = true;
      _result = 'جاري اختبار SQL Injection...';
    });

    final payloads = [
      "' OR '1'='1' --",
      "' OR 1=1--",
      "admin' --",
      "' UNION SELECT NULL--",
    ];

    for (final payload in payloads) {
      if (!mounted) return;
      setState(() => _result = 'اختبار: $payload');
      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() {
      _result = '✅ تم اكتشاف ثغرة SQL Injection محتملة\nالموقع: ${_targetController.text}\nالـ payloads: ${payloads.join(", ")}';
      _isAttacking = false;
    });
  }

  void _startAttack() {
    if (_targetController.text.isEmpty) {
      setState(() => _result = '⚠️ الرجاء إدخال الهدف');
      return;
    }

    switch (_selectedAttack) {
      case 'Brute Force':
        _bruteForce();
        break;
      case 'Dictionary':
        _dictionaryAttack();
        break;
      case 'SQL Injection':
        _sqlInjection();
        break;
    }
  }

  void _stopAttack() {
    setState(() {
      _isAttacking = false;
      _result = '⏹️ تم إيقاف الهجوم';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Database Hacking', style: TextStyle(color: Color(0xFF00FF41))),
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
            // نوع قاعدة البيانات
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDB,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Color(0xFF00FF41)),
                  items: _databases.map((db) => DropdownMenuItem(value: db, child: Text(db))).toList(),
                  onChanged: (v) => setState(() => _selectedDB = v!),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
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
                  items: _attacks.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
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
              ),
            ),
            const SizedBox(height: 10),
            
            // اسم المستخدم
            TextField(
              controller: _userController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم (اختياري)',
                labelStyle: TextStyle(color: Color(0xFF00FF41)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            
            // قاموس مخصص
            TextField(
              controller: _wordlistController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'قاموس مخصص (user:pass,user:pass)',
                labelStyle: TextStyle(color: Color(0xFF00FF41)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // أزرار التحكم
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAttacking ? null : _startAttack,
                    icon: _isAttacking ? const SizedBox(width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.flash_on),
                    label: const Text('بدء الهجوم'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            
            // النتيجة
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
                    _result.isEmpty ? 'نتائج الهجوم ستظهر هنا...' : _result,
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
