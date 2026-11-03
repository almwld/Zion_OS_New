import 'dart:convert';

import '../providers/ai_provider.dart';
import '../config/engine_mode.dart';
import 'command_policy.dart';
import 'error_classifier.dart';
import 'path_policy.dart';

class RepairHistoryEntry {
  const RepairHistoryEntry({
    required this.description,
    required this.verified,
    this.failureReason,
  });

  final String description;
  final bool verified;
  final String? failureReason;
}

class RepairSuggestion {
  const RepairSuggestion({
    required this.reasoning,
    required this.commands,
    required this.requiresElevation,
    required this.modifiesFiles,
  });

  final String reasoning;
  final List<String> commands;
  final bool requiresElevation;
  final bool modifiesFiles;
}

class LLMRepairAdvisor {
  LLMRepairAdvisor({
    required AIProvider Function() provider,
    CommandPolicy commandPolicy = const CommandPolicy(),
    required PathPolicy pathPolicy,
  })  : _provider = provider,
        _commandPolicy = commandPolicy,
        _pathPolicy = pathPolicy;

  final AIProvider Function() _provider;
  final CommandPolicy _commandPolicy;
  final PathPolicy _pathPolicy;

  Future<RepairSuggestion?> suggest({
    required ClassifiedError error,
    required List<RepairHistoryEntry> previousAttempts,
    required String failedCommand,
    bool sensitiveContext = false,
  }) async {
    final provider = _provider();
    final sensitive = sensitiveContext ||
        _looksSensitive(failedCommand) ||
        _looksSensitive(error.rawMessage);
    if (sensitive && provider.mode != EngineMode.local) return null;

    final history = previousAttempts.isEmpty
        ? '(لا توجد محاولات سابقة)'
        : previousAttempts
            .map((attempt) =>
                '- ${attempt.description}: '
                '${attempt.verified ? 'نجح' : 'فشل'} '
                '${attempt.failureReason ?? ''}')
            .join('\\n');

    final prompt = '''
حلل فشل الأمر واقترح خطوات تشخيص أو إصلاح محدودة وآمنة.
الأمر الفاشل: $failedCommand
نوع الخطأ: ${error.type.name}
رسالة الخطأ: ${error.rawMessage}
المحاولات السابقة:
$history

أعد كائن JSON واحداً فقط بهذه المفاتيح:
{"reasoning":"...","commands":["..."],"requiresElevation":false,"modifiesFiles":false}

القواعد:
- اقترح ثلاثة أوامر كحد أقصى.
- لا تستخدم sudo أو su أو rm أو mv أو chmod أو chown أو apt install.
- لا تستخدم pipe أو redirect أو command substitution أو سلاسل shell.
- لا تقترح كتابة ملفات أو حذفها أو تغيير صلاحياتها.
- لا تكرر الأمر الفاشل.
- إذا لم يوجد حل آمن فأعد commands كمصفوفة فارغة.
''';

    try {
      final raw = await provider.generate(
        systemPrompt: 'أنت مستشار إصلاح. لا تنفذ أوامر ولا تتجاوز سياسات الأمان.',
        prompt: prompt,
        maxTokens: 512,
        temperature: 0.2,
      );
      final suggestion = _parse(raw);
      if (suggestion == null ||
          suggestion.requiresElevation ||
          suggestion.modifiesFiles ||
          suggestion.commands.isEmpty ||
          suggestion.commands.length > 3) {
        return null;
      }

      for (final command in suggestion.commands) {
        if (command.trim().isEmpty ||
            command.length > 300 ||
            command == failedCommand ||
            !_commandPolicy.check(command).allowed ||
            !(await _pathPolicy.checkAsync(command)).allowed) {
          return null;
        }
      }
      return suggestion;
    } catch (_) {
      return null;
    }
  }

  bool _looksSensitive(String value) {
    return RegExp(
      r'(api[_-]?key|access[_-]?token|refresh[_-]?token|password|secret|authorization:|bearer\\s+[a-z0-9._-]{12,})',
      caseSensitive: false,
    ).hasMatch(value);
  }

  RepairSuggestion? _parse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded.keys.toSet().difference({
            'reasoning',
            'commands',
            'requiresElevation',
            'modifiesFiles',
          }).isNotEmpty) {
        return null;
      }

      final reasoning = decoded['reasoning'];
      final commands = decoded['commands'];
      final requiresElevation = decoded['requiresElevation'];
      final modifiesFiles = decoded['modifiesFiles'];
      if (reasoning is! String ||
          reasoning.length > 1000 ||
          commands is! List ||
          commands.any((item) => item is! String) ||
          requiresElevation is! bool ||
          modifiesFiles is! bool) {
        return null;
      }

      return RepairSuggestion(
        reasoning: reasoning,
        commands: List.unmodifiable(commands.cast<String>()),
        requiresElevation: requiresElevation,
        modifiesFiles: modifiesFiles,
      );
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
