import 'dart:io';

import 'package:flutter/material.dart';
import '../../../security/core/security_core.dart';
import '../../../security/runtime/runtime_integrity.dart';

class QualityAssurance extends StatefulWidget {
  const QualityAssurance({super.key});

  @override
  State<QualityAssurance> createState() => _QualityAssuranceState();
}

class _QualityAssuranceState extends State<QualityAssurance> {
  final SecurityCore _security = SecurityCore();
  final RuntimeIntegrity _integrity = const RuntimeIntegrity();
  RuntimeIntegrityReport? _report;
  bool _storageReady = false;
  bool _auditReady = false;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  void _runChecks() {
    final report = _integrity.verify(_security);
    final storage = Directory('/data/data/com.zion.os/files');
    final audit = File(_security.auditLogger.filePath);
    if (mounted) {
      setState(() {
        _report = report;
        _storageReady = storage.existsSync();
        _auditReady = audit.existsSync();
      });
    }
  }

  @override
  void dispose() {
    _security.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final checks = <String, bool>{
      'Runtime integrity': report?.passed ?? false,
      'Security capabilities': _security.capabilities.resolve('security.audit').availability.name == 'available',
      'App storage': _storageReady,
      'Audit path': _auditReady,
    };
    final passed = checks.values.where((v) => v).length;
    return Scaffold(
      backgroundColor: const Color(0xFF070B10),
      appBar: AppBar(
        title: const Text('فحص الجودة'),
        backgroundColor: const Color(0xFF101923),
        foregroundColor: const Color(0xFF00BCD4),
        actions: [
          IconButton(onPressed: _runChecks, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF101923),
            child: ListTile(
              leading: const Icon(Icons.fact_check, color: Color(0xFF00BCD4), size: 32),
              title: Text('نتيجة الفحص: ' + passed.toString() + '/' + checks.length.toString(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('فحوصات محلية قابلة لإعادة التشغيل', style: TextStyle(color: Colors.white60)),
            ),
          ),
          const SizedBox(height: 10),
          ...checks.entries.map((entry) => Card(
                color: const Color(0xFF0D151C),
                child: ListTile(
                  leading: Icon(entry.value ? Icons.check_circle : Icons.error_outline,
                      color: entry.value ? Colors.greenAccent : Colors.orangeAccent),
                  title: Text(entry.key, style: const TextStyle(color: Colors.white)),
                  trailing: Text(entry.value ? 'PASS' : 'CHECK',
                      style: TextStyle(color: entry.value ? Colors.greenAccent : Colors.orangeAccent,
                          fontWeight: FontWeight.bold)),
                ),
              )),
          const SizedBox(height: 12),
          const Text(
            'هذا فحص runtime محلي. اختبارات Flutter وBuild وAppetize تبقى مسؤولية CI ولا يتم تزوير نتائجها داخل التطبيق.',
            style: TextStyle(color: Colors.white54, height: 1.5),
          ),
        ],
      ),
    );
  }
}
