import 'llama_service.dart';

enum AgentRole { terminalAssistant, securityExpert, codingAssistant }
class AgentMessage { final String role; final String content; const AgentMessage({required this.role, required this.content}); }
enum RiskLevel { safe, medium, high, critical }
class CommandAnalysis {
  final String command; final String explanation; final RiskLevel riskLevel;
  const CommandAnalysis({required this.command, required this.explanation, required this.riskLevel});
}

class AIAgent {
  final LlamaService llama;
  final List<AgentMessage> _history = [];
  late AgentRole _role;
  bool _initialized = false;
  AIAgent({LlamaService? llama}) : llama = llama ?? LlamaService();
  bool get isInitialized => _initialized;

  Future<bool> initialize({required String modelPath, required AgentRole role, int nThreads = 2}) async {
    // A native model replacement first releases the previous model. Clear the
    // Dart readiness flag before crossing the platform channel so a failed
    // replacement can never leave the agent claiming that inference is ready.
    final previousModel = llama.currentModel;
    _initialized = false;
    final loaded = await llama.loadModel(modelPath, threads: nThreads);
    if (!loaded) return false;
    if (previousModel != null && previousModel != modelPath) {
      _history.clear();
    }
    _role = role;
    _initialized = true;
    return true;
  }

  Future<String> chat(
    String message, {
    int maxTokens = 128,
    double temperature = 0.25,
  }) async {
    if (!_initialized) return 'ERROR: الوكيل المحلي غير مهيأ.';
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return '';
    final rawResponse = await llama.generate(
      _buildPrompt(cleanMessage),
      maxTokens: maxTokens.clamp(1, 256).toInt(),
      temperature: temperature.clamp(0.0, 1.5).toDouble(),
    );
    final response = _cleanResponse(rawResponse);
    if (!response.startsWith('ERROR:')) {
      _history
        ..add(AgentMessage(role: 'user', content: cleanMessage))
        ..add(AgentMessage(role: 'assistant', content: response));
      if (_history.length > 12) _history.removeRange(0, _history.length - 12);
    }
    return response;
  }

  Future<CommandAnalysis> analyzeCommand(String command) async {
    final response = await llama.generate('''حلل أمر Linux التالي دفاعياً.
الأمر: $command
اذكر الوظيفة، الآثار الجانبية المحتملة، مستوى الخطر، وطريقة آمنة للتحقق قبل التنفيذ.
لا تنفذ الأمر ولا تقترح تجاوز صلاحيات أو اختراق أنظمة.''', maxTokens: 300, temperature: 0.25);
    return CommandAnalysis(command: command, explanation: response, riskLevel: _detectRisk(command));
  }

  Future<String> explainError(String error) => llama.generate(
    'اشرح الخطأ التالي بالعربية وحدد سبباً محتملاً وخطوات تشخيص وإصلاح آمنة:\n$error',
    maxTokens: 300, temperature: 0.25,
  );

  Future<String> translateCommand(String arabic) => llama.generate(
    'حوّل الطلب العربي التالي إلى أمر Linux مناسب، ثم أضف سطراً قصيراً يوضح ما سيفعله. لا تستخدم أوامر تدميرية:\n$arabic',
    maxTokens: 120, temperature: 0.2,
  );

  String _cleanResponse(String response) {
    var cleaned = response;
    for (final marker in const [
      '<|im_start|>', '<|im_end|>', '<|endoftext|>', '<|fim_suffix|>',
      '<|user|>', '<|assistant|>', '<|system|>', '<end>', '<user>',
      '<|end|>', '<|eot_id|>', '<|start_header_id|>', '<|end_header_id|>',
    ]) {
      cleaned = cleaned.replaceAll(marker, '');
    }
    final nextTurn = cleaned.indexOf(RegExp(r'\n\s*(User|Human|Assistant)\s*:', caseSensitive: false));
    if (nextTurn > 0) cleaned = cleaned.substring(0, nextTurn);
    return cleaned.trim();
  }

  String _buildPrompt(String message) {
    final b = StringBuffer()
      ..writeln('<|im_start|>system')
      ..writeln(_systemPrompt(_role))
      ..writeln('أجب عن الطلب الحالي فقط. لا تكرر رسالة الترحيب. إذا لم تعرف، صرّح بذلك.')
      ..writeln('<|im_end|>');
    final recent = _history.length > 4
        ? _history.sublist(_history.length - 4)
        : _history;
    for (final item in recent) {
      final content = item.content.length > 280
          ? item.content.substring(0, 280)
          : item.content;
      b
        ..writeln('<|im_start|>${item.role}')
        ..writeln(content)
        ..writeln('<|im_end|>');
    }
    final boundedMessage = message.length > 1200
        ? message.substring(0, 1200)
        : message;
    b
      ..writeln('<|im_start|>user')
      ..writeln(boundedMessage)
      ..writeln('<|im_end|>')
      ..writeln('<|im_start|>assistant');
    return b.toString();
  }

  String _systemPrompt(AgentRole role) => switch (role) {
    AgentRole.terminalAssistant => 'أنت مساعد طرفية محلي داخل Zion OS. أجب بالعربية، وفسّر الأوامر والأخطاء وقدّم خطوات آمنة.',
    AgentRole.securityExpert => 'أنت مساعد أمن دفاعي محلي. حلل الإعدادات والسجلات والأوامر بهدف التشخيص والحماية فقط.',
    AgentRole.codingAssistant => 'أنت مساعد برمجة محلي. اشرح وصحح الكود وراعِ بيئة Flutter وAndroid وLinux.',
  };

  RiskLevel _detectRisk(String command) {
    final c = command.toLowerCase();
    if (c.contains('rm -rf /') || c.contains('mkfs') || c.contains('dd if=') || c.contains(':(){')) return RiskLevel.critical;
    if (c.contains('rm ') || c.contains('chmod 777') || c.contains('sudo ') || c.contains('su ')) return RiskLevel.high;
    if (c.contains('apt ') || c.contains('pkg ') || c.contains('git clone')) return RiskLevel.medium;
    return RiskLevel.safe;
  }

  void restoreHistory(Iterable<AgentMessage> messages) {
    _history
      ..clear()
      ..addAll(messages.where((m) => m.role == 'user' || m.role == 'assistant').toList().reversed.take(20).toList().reversed);
  }

  void clearHistory() => _history.clear();
  Future<void> dispose() => llama.unloadModel();
}
