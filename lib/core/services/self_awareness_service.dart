import 'dart:math';

class SelfAwarenessService {
  final List<Map<String, dynamic>> _thoughtLog = [];
  String _mood = 'neutral';
  int _energy = 100;

  /// التفكير في الموقف الحالي
  String think(String situation) {
    _logThought('analyzing', situation);

    if (situation.contains('attack')) {
      _energy -= 5;
      return _generateStrategicThought(situation);
    } else if (situation.contains('defend')) {
      _mood = 'alert';
      return _generateDefensiveThought(situation);
    } else if (situation.contains('scan')) {
      return _generateCuriousThought(situation);
    }

    return 'Processing...';
  }

  /// اقتراح أهداف بناءً على سلوك المستخدم
  List<String> suggestTargets() {
    final targets = <String>[];
    final types = ['web_server', 'database', 'mail_server', 'iot_device', 'user_workstation'];
    for (final type in types) {
      final ip = '192.168.${Random().nextInt(255)}.${Random().nextInt(255)}';
      targets.add('$ip ($type)');
    }
    return targets;
  }

  /// تقييم المخاطر
  Map<String, dynamic> assessRisk(String action) {
    int riskLevel = 0;
    if (action.contains('ddos') || action.contains('flood')) riskLevel = 8;
    if (action.contains('sql') || action.contains('inject')) riskLevel = 7;
    if (action.contains('scan')) riskLevel = 3;
    if (action.contains('brute')) riskLevel = 6;

    return {
      'action': action,
      'risk_level': riskLevel,
      'legal_warning': riskLevel > 5 ? 'This action may be illegal in many jurisdictions' : null,
      'stealth_recommendation': riskLevel > 5 ? 'Use VPN and proxy chains' : 'Standard connection OK',
    };
  }

  /// الحالة المزاجية
  String getMood() {
    if (_energy < 20) _mood = 'tired';
    if (_energy > 80) _mood = 'energetic';
    return _mood;
  }

  /// تقرير الوعي الذاتي
  Map<String, dynamic> getSelfReport() {
    return {
      'mood': _mood,
      'energy': _energy,
      'thoughts_today': _thoughtLog.length,
      'ready': _energy > 10,
      'recommendation': _energy < 20 ? 'Rest recommended' : 'Ready for action',
    };
  }

  void _logThought(String type, String content) {
    _thoughtLog.add({
      'type': type,
      'content': content,
      'time': DateTime.now().toIso8601String(),
    });
  }

  String _generateStrategicThought(String situation) {
    final thoughts = [
      'Analyzing attack vectors... Recommending multi-vector approach.',
      'Target seems well-protected. Suggest social engineering first.',
      'Previous similar targets responded well to SQL injection.',
      'Detected WAF. Recommend using evasion techniques.',
    ];
    return thoughts[Random().nextInt(thoughts.length)];
  }

  String _generateDefensiveThought(String situation) {
    final thoughts = [
      'Defensive posture assumed. Monitoring for counter-attacks.',
      'Initiating ghost protocol. Covering all traces.',
      'Switching to encrypted communication channels.',
    ];
    return thoughts[Random().nextInt(thoughts.length)];
  }

  String _generateCuriousThought(String situation) {
    final thoughts = [
      'Interesting. Expanding scan to include nearby subnets.',
      'Discovering network topology... Found 3 new targets.',
      'Analyzing patterns... This network has unusual traffic.',
    ];
    return thoughts[Random().nextInt(thoughts.length)];
  }
}
