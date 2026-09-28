import 'dart:math';

class MissionPlanner {
  /// خطط المهمة الكاملة للوصول إلى الهدف
  static List<Map<String, dynamic>> planMission(String target, String goal) {
    final steps = <Map<String, dynamic>>[];
    int stepNum = 1;

    // المرحلة 1: الاستطلاع
    steps.add(_createStep(stepNum++, 'Reconnaissance', 'Scan target for open ports', 'port_scan', target));
    steps.add(_createStep(stepNum++, 'Reconnaissance', 'Enumerate DNS records', 'dns_enum', target));
    steps.add(_createStep(stepNum++, 'Reconnaissance', 'Check SSL certificate', 'ssl_check', target));
    steps.add(_createStep(stepNum++, 'Reconnaissance', 'Find subdomains', 'subdomain', target));

    // المرحلة 2: التحليل
    steps.add(_createStep(stepNum++, 'Analysis', 'Identify services and versions', 'service_detect', target));
    steps.add(_createStep(stepNum++, 'Analysis', 'Check vulnerability database', 'vuln_scan', target));

    // المرحلة 3: الهجوم
    if (goal.contains('access') || goal.contains('shell')) {
      steps.add(_createStep(stepNum++, 'Exploitation', 'Attempt SQL injection', 'sql_test', target));
      steps.add(_createStep(stepNum++, 'Exploitation', 'Brute force common passwords', 'brute_force', target));
      steps.add(_createStep(stepNum++, 'Exploitation', 'Deploy payload via Metasploit', 'metasploit', target));
    }

    if (goal.contains('ddos') || goal.contains('take down')) {
      steps.add(_createStep(stepNum++, 'DoS', 'HTTP Flood attack', 'http_flood', target));
      steps.add(_createStep(stepNum++, 'DoS', 'Slowloris attack', 'slowloris', target));
    }

    if (goal.contains('data') || goal.contains('steal')) {
      steps.add(_createStep(stepNum++, 'Exfiltration', 'Dump database contents', 'sql_dump', target));
      steps.add(_createStep(stepNum++, 'Exfiltration', 'Extract sensitive files', 'file_extract', target));
    }

    // المرحلة 4: التغطية
    steps.add(_createStep(stepNum++, 'Cover Tracks', 'Clear logs', 'clear_logs', target));
    steps.add(_createStep(stepNum++, 'Cover Tracks', 'Remove backdoors', 'cleanup', target));

    // المرحلة 5: التقرير
    steps.add(_createStep(stepNum++, 'Report', 'Generate mission report', 'report', target));

    return steps;
  }

  static Map<String, dynamic> _createStep(int num, String phase, String description, String command, String target) {
    return {
      'step': num,
      'phase': phase,
      'description': description,
      'command': command,
      'target': target,
      'status': 'pending',
      'result': null,
    };
  }

  /// تقدير وقت المهمة
  static String estimateMissionTime(List<Map<String, dynamic>> steps) {
    int totalSeconds = 0;
    for (final step in steps) {
      switch (step['command']) {
        case 'port_scan':
          totalSeconds += 120;
          break;
        case 'dns_enum':
          totalSeconds += 30;
          break;
        case 'sql_test':
          totalSeconds += 60;
          break;
        case 'http_flood':
          totalSeconds += 600;
          break;
        default:
          totalSeconds += 45;
      }
    }

    if (totalSeconds < 60) return '${totalSeconds}s';
    if (totalSeconds < 3600) return '${(totalSeconds / 60).round()}m';
    return '${(totalSeconds / 3600).round()}h';
  }

  /// تقييم صعوبة المهمة
  static String assessDifficulty(String target, String goal) {
    int score = 0;

    if (target.contains('.gov') || target.contains('.mil')) score += 3;
    if (target.contains('.bank') || target.contains('finance')) score += 2;
    if (goal.contains('ddos')) score += 1;
    if (goal.contains('data')) score += 2;
    if (goal.contains('root')) score += 3;

    if (score >= 6) return 'EXTREME';
    if (score >= 4) return 'HARD';
    if (score >= 2) return 'MEDIUM';
    return 'EASY';
  }
}
