import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ReportGenerator extends StatefulWidget {
  const ReportGenerator({super.key});

  @override
  State<ReportGenerator> createState() => _ReportGeneratorState();
}

class _ReportGeneratorState extends State<ReportGenerator> {
  final List<Map<String, dynamic>> _reports = [];

  void _generateReport() {
    final newReport = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': DateTime.now().toString(),
      'target': '192.168.1.1',
      'findings': [
        'Open Ports: 22, 80, 443, 3306',
        'Vulnerabilities: EternalBlue, Heartbleed',
        'Credentials: admin:password',
      ],
    };
    
    setState(() {
      _reports.insert(0, newReport);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report generated')),
    );
  }

  void _shareReport(Map<String, dynamic> report) {
    final content = '''
=== ZION OS SECURITY REPORT ===
ID: ${report['id']}
Date: ${report['date']}
Target: ${report['target']}
Findings:
${(report['findings'] as List).map((f) => '- $f').join('\n')}
===============================
''';
    Share.share(content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Report Generator'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _generateReport,
          ),
        ],
      ),
      body: _reports.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, color: Colors.grey, size: 64),
                  SizedBox(height: 16),
                  Text('No reports yet', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap + to generate a report', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (ctx, i) => Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text('Report ${_reports[i]['id']}', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(_reports[i]['date'], style: const TextStyle(color: Colors.grey)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Target: ${_reports[i]['target']}', style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 8),
                          const Text('Findings:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          ...(_reports[i]['findings'] as List).map((f) => Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Text('• $f', style: const TextStyle(color: Colors.white70)),
                          )),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _shareReport(_reports[i]),
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
