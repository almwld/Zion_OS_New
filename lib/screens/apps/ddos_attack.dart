import 'package:flutter/material.dart';

/// Defensive training screen. Network flooding is intentionally not executed
/// or simulated. The production app must never report fabricated packets or
/// pretend that a denial-of-service attack occurred.
class DDoSAttackApp extends StatefulWidget {
  const DDoSAttackApp({super.key});

  @override
  State<DDoSAttackApp> createState() => _DDoSAttackAppState();
}

class _DDoSAttackAppState extends State<DDoSAttackApp> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '80');
  final List<String> _attackTypes = const [
    'SYN Flood',
    'UDP Flood',
    'HTTP Flood',
    'Slowloris',
    'Ping of Death',
  ];
  String _selectedAttack = 'SYN Flood';
  String _status = 'الوضع التدريبي فقط: لا يتم إرسال أو محاكاة أي حركة هجومية.';

  @override
  void dispose() {
    _targetController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _showDisabled() {
    setState(() {
      _status = 'تم منع التنفيذ. هذه الشاشة مخصصة للتوعية الدفاعية وتحليل مخاطر DDoS فقط.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DDoS — تدريب دفاعي'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Zion OS لا ينفذ ولا يحاكي هجمات حجب الخدمة. استخدم هذه الواجهة لفهم الأنواع ومؤشرات الدفاع فقط.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedAttack,
              items: _attackTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedAttack = value);
              },
              decoration: const InputDecoration(labelText: 'نوع السيناريو'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: 'الهدف للتحليل (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المنفذ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showDisabled,
                icon: const Icon(Icons.block),
                label: const Text('التنفيذ محظور — عرض التحذير'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'السيناريو: $_selectedAttack\n\n$_status',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
