import 'package:flutter/material.dart';

class DocsCenter extends StatelessWidget {
  const DocsCenter({super.key});

  static const _docs = <Map<String, String>>[
    {'title': 'Architecture', 'detail': 'حدود التطبيق، الخدمات، وإدارة النوافذ'},
    {'title': 'Zion API', 'detail': 'واجهة Android-native وقدرات النظام'},
    {'title': 'Production Release', 'detail': 'مخرجات APK/AAB والتحقق من الإصدار'},
    {'title': 'Security Policy', 'detail': 'حدود الاستخدام الدفاعي والعزل'},
    {'title': 'Implementation Status', 'detail': 'حالة الميزات المبنية على أدلة فعلية'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B10),
      appBar: AppBar(
        title: const Text('مركز التوثيق'),
        backgroundColor: const Color(0xFF101923),
        foregroundColor: const Color(0xFF00BCD4),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            color: Color(0xFF101923),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'مرجع Zion OS\n'
                'التوثيق يصف القدرات الفعلية وحدود الإنتاج، ولا يعتبر الميزة مكتملة لمجرد وجود واجهة لها.',
                style: TextStyle(color: Colors.white70, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._docs.map((doc) => Card(
                color: const Color(0xFF0D151C),
                child: ListTile(
                  leading: const Icon(Icons.description, color: Color(0xFF00BCD4)),
                  title: Text(doc['title']!, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(doc['detail']!, style: const TextStyle(color: Colors.white60)),
                ),
              )),
        ],
      ),
    );
  }
}
