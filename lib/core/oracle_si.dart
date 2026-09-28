import 'dart:async';

class OracleSi {
  static final OracleSi _instance = OracleSi._internal();
  factory OracleSi() => _instance;
  OracleSi._internal();

  final Map<String, dynamic> _globalThreatPatterns = {};
  bool _isActive = false;

  Future<void> activate() async {
    _isActive = true;
    print('🔮 Oracle SI activated');
  }

  Future<void> deactivate() async {
    _isActive = false;
    print('🔮 Oracle SI deactivated');
  }

  Future<Map<String, dynamic>> predictThreat(Map<String, dynamic> context) async {
    // ✅ إصلاح: تحويل Object? إلى String
    final threatType = context['type']?.toString() ?? 'unknown';
    
    if (!_globalThreatPatterns.containsKey(threatType)) {
      _globalThreatPatterns[threatType] = {
        'type': threatType,
        'confidence': 0.5,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    return {
      'prediction': _globalThreatPatterns[threatType],
      'confidence': 0.75,
    };
  }

  Future<List<String>> getActiveThreats() async {
    return _globalThreatPatterns.keys.toList();
  }

  bool isActive() => _isActive;
}
