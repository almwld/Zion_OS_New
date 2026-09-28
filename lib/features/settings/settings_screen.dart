import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('عام'),
          SwitchListTile(title: const Text('الوضع الليلي', style: TextStyle(color: Colors.white)), value: true, onChanged: (_) {}, activeColor: const Color(0xFF00FF41)),
          SwitchListTile(title: const Text('الإشعارات', style: TextStyle(color: Colors.white)), value: true, onChanged: (_) {}, activeColor: const Color(0xFF00FF41)),
          const Divider(),
          const _SectionTitle('الشبكة'),
          ListTile(title: const Text('وكيل HTTP', style: TextStyle(color: Colors.white)), subtitle: const Text('لم يتم التعيين', style: TextStyle(color: Colors.grey)), trailing: const Icon(Icons.edit, color: Color(0xFF00FF41))),
          const Divider(),
          const _SectionTitle('حول'),
          const ListTile(title: Text('الإصدار', style: TextStyle(color: Colors.white)), subtitle: Text('2.0.0', style: TextStyle(color: Colors.grey))),
          const ListTile(title: Text('الترخيص', style: TextStyle(color: Colors.white)), subtitle: Text('MIT License', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
