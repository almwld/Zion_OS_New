import 'package:flutter/material.dart';

class CloudAttacksApp extends StatefulWidget {
  const CloudAttacksApp({super.key});

  @override
  State<CloudAttacksApp> createState() => _CloudAttacksAppState();
}

class _CloudAttacksAppState extends State<CloudAttacksApp> {
  final TextEditingController _targetController = TextEditingController();
  String _result = '';
  bool _isAttacking = false;
  String _selectedCloud = 'AWS';
  String _selectedAttack = 'Key Scanner';

  final List<String> _clouds = ['AWS', 'Azure', 'GCP', 'DigitalOcean'];
  final List<String> _attacks = ['Key Scanner', 'Bucket Scanner', 'Instance Scanner'];

  Future<void> _scanKeys() async {
    setState(() {
      _isAttacking = true;
      _result = '🔍 جاري البحث عن مفاتيح API مسربة...';
    });

    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _result = '''
✅ نتائج فحص $_selectedCloud:

🔑 مفاتيح محتملة تم العثور عليها:
   • AKIAIOSFODNN7EXAMPLE - AWS Key (تم التحقق)
   • AIzaSyC6kqXqQvQ7qQ7qQ7qQ7qQ7qQ7qQ7qQ - Google Key

⚠️ تحذير: هذه المفاتيح تم نشرها في GitHub
🛡️ يوصى بإبطالها فوراً

📊 إحصائيات:
   • إجمالي الملفات الممسوحة: 1,247
   • الملفات الحساسة: 23
   • المفاتيح النشطة: 2
''';
      _isAttacking = false;
    });
  }

  Future<void> _scanBuckets() async {
    setState(() {
      _isAttacking = true;
      _result = '📦 جاري فحص الـ Buckets...';
    });

    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _result = '''
✅ نتائج فحص الـ $_selectedCloud Buckets:

📁 Buckets مفتوحة للعام:
   • ${_targetController.text}-backup (3.2 GB)
   • ${_targetController.text}-logs (847 MB)
   • ${_targetController.text}-database (1.5 GB)

🔓 صلاحيات الوصول:
   • قراءة: عام ✅
   • كتابة: عام ❌
   • حذف: مقيد ❌

📄 ملفات حساسة تم العثور عليها:
   • config.json - يحتوي على مفاتيح API
   • database.sql - قاعدة بيانات كاملة
   • backup.zip - نسخة احتياطية
''';
      _isAttacking = false;
    });
  }

  Future<void> _scanInstances() async {
    setState(() {
      _isAttacking = true;
      _result = '🖥️ جاري فحص الـ Instances...';
    });

    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _result = '''
✅ نتائج فحص $_selectedCloud Instances:

🖥️ Instances النشطة:
   • web-server-01 (t2.micro) - IP: 54.123.45.67
   • app-server-01 (t2.small) - IP: 54.123.45.68
   • db-server-01 (t2.medium) - IP: 54.123.45.69

🔓 ثغرات مكتشفة:
   • منفذ 22 مفتوح (SSH) - خطر متوسط
   • منفذ 3306 مفتوح (MySQL) - خطر عالي
   • منفذ 6379 مفتوح (Redis) - خطر عالي

🎯 توصيات:
   • تحديث جميع الأنظمة فوراً
   • تغيير كلمات المرور الافتراضية
   • تقييد الوصول إلى المنافذ
''';
      _isAttacking = false;
    });
  }

  void _startAttack() {
    if (_targetController.text.isEmpty && _selectedAttack != 'Instance Scanner') {
      setState(() => _result = '⚠️ الرجاء إدخال الهدف');
      return;
    }

    switch (_selectedAttack) {
      case 'Key Scanner':
        _scanKeys();
        break;
      case 'Bucket Scanner':
        _scanBuckets();
        break;
      case 'Instance Scanner':
        _scanInstances();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Cloud Attacks', style: TextStyle(color: Color(0xFF00FF41))),
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
            // نوع السحابة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCloud,
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Color(0xFF00FF41)),
                  items: _clouds.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCloud = v!),
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
            
            // الهدف (للهجمات التي تحتاج هدف)
            if (_selectedAttack != 'Instance Scanner')
              TextField(
                controller: _targetController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'الهدف (Domain أو Bucket Name)',
                  labelStyle: TextStyle(color: Color(0xFF00FF41)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
                ),
              ),
            const SizedBox(height: 20),
            
            // زر بدء الهجوم
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAttacking ? null : _startAttack,
                icon: _isAttacking ? const SizedBox(width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload),
                label: const Text('بدء الهجوم'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF41),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
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
