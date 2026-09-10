import 'package:flutter/material.dart';

class AICommand {
  final String query;
  final String response;
  final String action;

  const AICommand({
    required this.query,
    required this.response,
    required this.action,
  });
}

class ZionAIAssistant extends ChangeNotifier {
  final List<Map<String, dynamic>> _conversation = [];
  bool _isProcessing = false;
  bool _voiceEnabled = false;

  final List<AICommand> _knownCommands = const [
    AICommand(
      query: 'حالة النظام',
      response: 'الأمر معروف. استخدم تشخيص النظام لقراءة البيانات الفعلية من الجهاز.',
      action: 'system_info',
    ),
    AICommand(
      query: 'معلومات الشبكة',
      response: 'الأمر معروف. يمكن قراءة حالة الشبكة الفعلية من خدمات النظام المتاحة.',
      action: 'network_info',
    ),
    AICommand(
      query: 'فحص DNS',
      response: 'الأمر معروف. يمكن تنفيذ فحص DNS فعلي عند توفر الاتصال.',
      action: 'dns_lookup',
    ),
    AICommand(
      query: 'اختبر الاتصال',
      response: 'الأمر معروف. يمكن تنفيذ اختبار اتصال فعلي.',
      action: 'ping',
    ),
  ];

  List<Map<String, dynamic>> get conversation => List.unmodifiable(_conversation);
  bool get isProcessing => _isProcessing;
  bool get voiceEnabled => _voiceEnabled;

  void toggleVoice() {
    _voiceEnabled = !_voiceEnabled;
    notifyListeners();
  }

  Future<void> ask(String query) async {
    final text = query.trim();
    if (text.isEmpty || _isProcessing) return;

    _conversation.add({
      'role': 'user',
      'text': text,
      'time': DateTime.now(),
    });
    _isProcessing = true;
    notifyListeners();

    AICommand? match;
    for (final command in _knownCommands) {
      if (text.contains(command.query)) {
        match = command;
        break;
      }
    }

    final response = match?.response ??
        'لم يتم تنفيذ أي إجراء. الأوامر المتاحة هنا هي إرشادات مرتبطة بخدمات حقيقية، ولا يتم ادعاء نجاح عملية لم تُنفذ.';

    _conversation.add({
      'role': 'ai',
      'text': response,
      'time': DateTime.now(),
      'action': match?.action,
    });
    _isProcessing = false;
    notifyListeners();
  }

  void clearConversation() {
    _conversation.clear();
    notifyListeners();
  }
}
