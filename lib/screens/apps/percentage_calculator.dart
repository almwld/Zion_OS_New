import 'package:flutter/material.dart';

class PercentageCalculatorApp extends StatefulWidget {
  const PercentageCalculatorApp({super.key});

  @override
  State<PercentageCalculatorApp> createState() => _PercentageCalculatorAppState();
}

class _PercentageCalculatorAppState extends State<PercentageCalculatorApp> {
  final TextEditingController _valueController = TextEditingController(text: '100');
  final TextEditingController _percentController = TextEditingController(text: '20');
  String _result = '20';

  void _calculate() {
    final value = double.tryParse(_valueController.text) ?? 0;
    final percent = double.tryParse(_percentController.text) ?? 0;
    final result = (percent / 100) * value;
    setState(() {
      _result = result.toStringAsFixed(2);
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Percentage Calculator', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('What is X% of Y?', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 18)),
            const SizedBox(height: 30),
            TextField(
              controller: _percentController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculate(),
              decoration: const InputDecoration(
                labelText: 'Percentage (%)',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculate(),
              decoration: const InputDecoration(
                labelText: 'Value',
                labelStyle: TextStyle(color: Color(0xFF00BCD4)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF006064)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Result', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('$_result', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
