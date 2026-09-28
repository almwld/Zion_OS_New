import 'dart:convert';

import 'package:flutter/material.dart';

enum ReportFormat { pdf, html, json, txt }
enum ReportType { scanResult, vulnerability, penetration, audit, summary }

class ZionReport {
  final String id;
  final String title;
  final ReportType type;
  final DateTime createdAt;
  final ReportFormat format;
  final int size;
  final String summary;

  ZionReport({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.format,
    required this.size,
    required this.summary,
  });
}

class ZionReportingSystem extends ChangeNotifier {
  final List<ZionReport> _reports = [];
  bool _isGenerating = false;
  int _progress = 0;

  List<ZionReport> get reports => List.unmodifiable(_reports.reversed.toList());
  bool get isGenerating => _isGenerating;
  int get progress => _progress;

  Future<ZionReport> generateReport({
    required String title,
    required ReportType type,
    required ReportFormat format,
    required Map<String, dynamic> data,
  }) async {
    if (_isGenerating) throw StateError('يوجد تقرير قيد الإنشاء');
    _isGenerating = true;
    _progress = 0;
    notifyListeners();

    final now = DateTime.now();
    final payload = <String, dynamic>{
      'title': title,
      'type': type.name,
      'format': format.name,
      'createdAt': now.toIso8601String(),
      'data': data,
    };
    final encoded = jsonEncode(payload);
    final summary = 'تقرير $title - ${type.name} - ${format.name}';

    // Generation is synchronous and based on the supplied data. Progress is
    // reported only for completed work; there is no artificial delay.
    _progress = 100;
    final report = ZionReport(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      type: type,
      createdAt: now,
      format: format,
      size: utf8.encode(encoded).length,
      summary: summary,
    );
    _reports.add(report);
    _isGenerating = false;
    notifyListeners();
    return report;
  }

  void deleteReport(String id) {
    _reports.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void exportReport(ZionReport report) {
    // Export requires a platform file/share implementation. Do not claim
    // success from a no-op method.
  }
}
