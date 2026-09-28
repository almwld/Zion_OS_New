import 'dart:io';
import 'dart:convert';

class VulnManagementSystem {
  final List<Map<String, dynamic>> _vulnDatabase = [];
  final List<Map<String, dynamic>> _scanHistory = [];

  /// إضافة ثغرة مكتشفة
  void addVulnerability({
    required String target,
    required int port,
    required String name,
    required String severity,
    String? cve,
    String? description,
    String? remediation,
  }) {
    _vulnDatabase.add({
      'id': _vulnDatabase.length + 1,
      'target': target,
      'port': port,
      'name': name,
      'severity': severity,
      'cve': cve ?? '',
      'description': description ?? '',
      'remediation': remediation ?? '',
      'discovered_at': DateTime.now().toIso8601String(),
      'status': 'open',
    });
  }

  /// الحصول على كل الثغرات
  List<Map<String, dynamic>> getAllVulnerabilities({String? severity}) {
    if (severity != null) {
      return _vulnDatabase.where((v) => v['severity'] == severity).toList();
    }
    return _vulnDatabase;
  }

  /// الحصول على ثغرات هدف محدد
  List<Map<String, dynamic>> getVulnerabilitiesForTarget(String target) {
    return _vulnDatabase.where((v) => v['target'] == target).toList();
  }

  /// تحديث حالة ثغرة
  void updateStatus(int id, String status) {
    final index = _vulnDatabase.indexWhere((v) => v['id'] == id);
    if (index != -1) {
      _vulnDatabase[index]['status'] = status;
      _vulnDatabase[index]['updated_at'] = DateTime.now().toIso8601String();
    }
  }

  /// توليد تقرير شامل
  String generateReport({String? target}) {
    final vulns = target != null ? getVulnerabilitiesForTarget(target) : _vulnDatabase;
    final report = StringBuffer();

    report.writeln('=' * 60);
    report.writeln('VULNERABILITY MANAGEMENT REPORT');
    report.writeln('=' * 60);
    report.writeln('Generated: ${DateTime.now().toIso8601String()}');
    if (target != null) report.writeln('Target: $target');
    report.writeln('');

    final critical = vulns.where((v) => v['severity'] == 'Critical').length;
    final high = vulns.where((v) => v['severity'] == 'High').length;
    final medium = vulns.where((v) => v['severity'] == 'Medium').length;
    final low = vulns.where((v) => v['severity'] == 'Low').length;

    report.writeln('SUMMARY:');
    report.writeln('  Critical: $critical');
    report.writeln('  High: $high');
    report.writeln('  Medium: $medium');
    report.writeln('  Low: $low');
    report.writeln('  Total: ${vulns.length}');
    report.writeln('');

    for (final vuln in vulns) {
      report.writeln('[${vuln['severity']}] ${vuln['name']}');
      report.writeln('  Target: ${vuln['target']}:${vuln['port']}');
      if (vuln['cve'].isNotEmpty) report.writeln('  CVE: ${vuln['cve']}');
      if (vuln['remediation'].isNotEmpty) report.writeln('  Fix: ${vuln['remediation']}');
      report.writeln('  Status: ${vuln['status']}');
      report.writeln('');
    }

    report.writeln('=' * 60);
    return report.toString();
  }

  /// تصدير إلى JSON
  String exportToJson() {
    return const JsonEncoder.withIndent('  ').convert(_vulnDatabase);
  }

  /// استيراد من JSON
  void importFromJson(String json) {
    final data = jsonDecode(json) as List<dynamic>;
    for (final item in data) {
      _vulnDatabase.add(Map<String, dynamic>.from(item as Map));
    }
  }

  /// إحصائيات
  Map<String, int> getStats() {
    return {
      'total': _vulnDatabase.length,
      'open': _vulnDatabase.where((v) => v['status'] == 'open').length,
      'closed': _vulnDatabase.where((v) => v['status'] == 'closed').length,
      'false_positive': _vulnDatabase.where((v) => v['status'] == 'false_positive').length,
    };
  }
}
