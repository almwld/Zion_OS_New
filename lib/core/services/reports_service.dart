import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ReportsService {
  static final ReportsService _instance = ReportsService._internal();
  factory ReportsService() => _instance;
  ReportsService._internal();
  
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic> _statistics = {};
  
  Future<void> init() async {
    await _loadReports();
    await _loadStatistics();
  }
  
  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getString('reports');
    if (reportsJson != null) {
      try {
        _reports = List<Map<String, dynamic>>.from(jsonDecode(reportsJson));
      } catch (_) {}
    }
  }
  
  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('statistics');
    if (statsJson != null) {
      try {
        _statistics = jsonDecode(statsJson) as Map<String, dynamic>;
      } catch (_) {}
    }
    
    if (_statistics.isEmpty) {
      _statistics = {
        'total_scans': 0,
        'total_attacks': 0,
        'total_detections': 0,
        'total_backups': 0,
        'uptime': 0,
        'last_scan': null,
        'last_attack': null,
      };
    }
  }
  
  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reports', jsonEncode(_reports));
  }
  
  Future<void> _saveStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('statistics', jsonEncode(_statistics));
  }
  
  Future<void> addReport(String title, String type, Map<String, dynamic> data) async {
    final report = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _reports.insert(0, report);
    if (_reports.length > 50) _reports = _reports.sublist(0, 50);
    await _saveReports();
    
    // Update statistics
    if (type == 'scan') _statistics['total_scans'] = (_statistics['total_scans'] ?? 0) + 1;
    if (type == 'attack') _statistics['total_attacks'] = (_statistics['total_attacks'] ?? 0) + 1;
    if (type == 'detection') _statistics['total_detections'] = (_statistics['total_detections'] ?? 0) + 1;
    if (type == 'backup') _statistics['total_backups'] = (_statistics['total_backups'] ?? 0) + 1;
    _statistics['last_${type}'] = DateTime.now().toIso8601String();
    await _saveStatistics();
  }
  
  Future<void> exportReport(String reportId) async {
    final report = _reports.firstWhere((r) => r['id'] == reportId);
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/exports');
    await exportDir.create(recursive: true);
    
    final exportFile = File('${exportDir.path}/report_${reportId}.json');
    await exportFile.writeAsString(jsonEncode(report));
  }
  
  Future<void> deleteReport(String reportId) async {
    _reports.removeWhere((r) => r['id'] == reportId);
    await _saveReports();
  }
  
  Future<void> clearAllReports() async {
    _reports.clear();
    await _saveReports();
  }
  
  List<Map<String, dynamic>> getReports({String? type, int? limit}) {
    var filtered = _reports;
    if (type != null) {
      filtered = filtered.where((r) => r['type'] == type).toList();
    }
    if (limit != null && limit > 0) {
      filtered = filtered.take(limit).toList();
    }
    return filtered;
  }
  
  Map<String, dynamic> getStatistics() => _statistics;
  
  Map<String, dynamic> getDashboardStats() {
    return {
      'total_reports': _reports.length,
      'scans': _statistics['total_scans'] ?? 0,
      'attacks': _statistics['total_attacks'] ?? 0,
      'detections': _statistics['total_detections'] ?? 0,
      'backups': _statistics['total_backups'] ?? 0,
    };
  }
  
  List<Map<String, dynamic>> getRecentReports({int count = 10}) {
    return _reports.take(count).toList();
  }
}

// Helper functions
String jsonEncode(Map<String, dynamic> data) {
  return data.toString();
}

List<Map<String, dynamic>> jsonDecode(String data) {
  return [];
}
