class NeuralAnalysisResult {
  final String command;
  final int riskLevel;
  final bool requiresConfirmation;
  final List<String> suggestions;
  final DateTime timestamp;

  const NeuralAnalysisResult({
    required this.command,
    required this.riskLevel,
    required this.requiresConfirmation,
    required this.suggestions,
    required this.timestamp,
  });
}

/// Lightweight on-device command analysis. It classifies commands and suggests
/// safe alternatives; it never executes commands or generates attack payloads.
class NeuralAnalyzer {
  static const _dangerousTokens = <String>[
    'rm -rf',
    'mkfs',
    'dd if=',
    'chmod 777',
    'curl | sh',
    'wget | sh',
    'sudo',
  ];

  static const _securityTools = <String>[
    'nmap',
    'hydra',
    'sqlmap',
    'metasploit',
    'aircrack',
    'hashcat',
    'john',
    'nikto',
  ];

  Future<NeuralAnalysisResult> analyzeCommand(String command) async {
    final normalized = command.trim().toLowerCase();
    var risk = 0;
    if (_dangerousTokens.any(normalized.contains)) risk += 70;
    if (_securityTools.any(normalized.contains)) risk += 20;
    if (normalized.contains('> /dev/') || normalized.contains('mkfs')) risk += 20;
    risk = risk.clamp(0, 100);

    final suggestions = <String>[];
    if (normalized.isEmpty) {
      suggestions.add('أدخل أمرًا لتحليله.');
    } else if (risk >= 70) {
      suggestions.add('راجع نطاق العملية والصلاحيات قبل التنفيذ.');
      suggestions.add('استخدم بيئة اختبار معزولة عند الحاجة.');
    } else if (_securityTools.any(normalized.contains)) {
      suggestions.add('استخدم أدوات الفحص على الأنظمة التي تملك تصريحًا لاختبارها فقط.');
    } else {
      suggestions.add('الأمر منخفض المخاطر وفق قواعد التحليل المحلية.');
    }

    return NeuralAnalysisResult(
      command: command,
      riskLevel: risk,
      requiresConfirmation: risk >= 70,
      suggestions: suggestions,
      timestamp: DateTime.now(),
    );
  }
}
