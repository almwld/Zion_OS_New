import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ReportCard(title: 'تقرير فحص المنافذ', date: '2024-06-09', target: '192.168.1.1', status: 'مكتمل'),
          _ReportCard(title: 'تقرير فحص الثغرات', date: '2024-06-08', target: '192.168.1.100', status: 'مكتمل'),
          _ReportCard(title: 'تقرير تحليل الحزم', date: '2024-06-07', target: '192.168.1.0/24', status: 'قيد الانتظار'),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title, date, target, status;
  const _ReportCard({required this.title, required this.date, required this.target, required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(status == 'مكتمل' ? Icons.check_circle : Icons.hourglass_empty, color: status == 'مكتمل' ? const Color(0xFF00FF41) : Colors.orange),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text('الهدف: $target | التاريخ: $date', style: const TextStyle(color: Colors.grey)),
        trailing: Text(status, style: TextStyle(color: status == 'مكتمل' ? const Color(0xFF00FF41) : Colors.orange)),
      ),
    );
  }
}
