enum ErrorType { commandNotFound, permissionDenied, networkError, missingDependency, buildError, storageFull, outOfMemory, unknown }

class ClassifiedError {
  const ClassifiedError({required this.type, required this.rawMessage, this.command, this.path, this.metadata = const {}});
  final ErrorType type;
  final String rawMessage;
  final String? command;
  final String? path;
  final Map<String, String> metadata;
}

class RepairStrategy {
  const RepairStrategy({required this.description, this.diagnosticCommands = const [], this.repairCommands = const [], this.requiresElevation = false, this.modifiesSystem = false});
  final String description;
  final List<String> diagnosticCommands;
  final List<String> repairCommands;
  final bool requiresElevation;
  final bool modifiesSystem;
}

class ErrorClassifier {
  ClassifiedError classify(String stdout, String stderr, int exitCode, {String? command}) {
    final raw = [stderr, stdout].where((s) => s.trim().isNotEmpty).join('\n').trim();
    final text = raw.toLowerCase();
    ErrorType type;
    if (RegExp(r'command not found|not found:|is not recognized as an internal').hasMatch(text)) {
      type = ErrorType.commandNotFound;
    } else if (RegExp(r'permission denied|a password is required|operation not permitted').hasMatch(text)) {
      type = ErrorType.permissionDenied;
    } else if (RegExp(r'could not resolve|connection refused|network is unreachable|temporary failure in name resolution').hasMatch(text)) {
      type = ErrorType.networkError;
    } else if (RegExp(r'no such file or directory|not installed|cannot find package|package .* not found').hasMatch(text)) {
      type = ErrorType.missingDependency;
    } else if (RegExp(r'no space left|disk quota exceeded').hasMatch(text)) {
      type = ErrorType.storageFull;
    } else if (RegExp(r'out of memory|\bkilled\b|cannot allocate memory').hasMatch(text)) {
      type = ErrorType.outOfMemory;
    } else if (text.contains('error:') || (command?.contains('flutter build') ?? false) || (command?.contains('dart analyze') ?? false)) {
      type = ErrorType.buildError;
    } else {
      type = ErrorType.unknown;
    }
    final pathMatch = RegExp(r'(?:(?:/|~/)[^\s:]+)').firstMatch(raw);
    final commandMatch = RegExp(r"(?:bash:|sh:)?\s*([A-Za-z0-9_.+-]+):\s*(?:command not found|not found)").firstMatch(raw);
    return ClassifiedError(type: type, rawMessage: raw.isEmpty ? 'exit code $exitCode' : raw,
      command: commandMatch?.group(1) ?? command, path: pathMatch?.group(0),
      metadata: {'exitCode': '$exitCode'});
  }

  RepairStrategy suggestStrategy(ClassifiedError error) {
    switch (error.type) {
      case ErrorType.commandNotFound:
        final name = error.command?.split(RegExp(r'\s+')).first ?? '';
        if (!RegExp(r'^[A-Za-z0-9_.+-]{1,80}$').hasMatch(name)) {
          return const RepairStrategy(description: 'اسم الأمر غير آمن للتشخيص الآلي.');
        }
        return RepairStrategy(description: 'تحقق من توفر الأمر ومسارات PATH؛ لا تثبّت برامج تلقائياً.',
          diagnosticCommands: ['which $name', 'echo PATH', 'pwd']);
      case ErrorType.permissionDenied:
        return const RepairStrategy(description: 'فحص هوية المستخدم وصلاحيات المسار؛ يتطلب أي تغيير صلاحيات موافقة منفصلة.',
          diagnosticCommands: ['id', 'ls -la']);
      case ErrorType.networkError:
        return const RepairStrategy(description: 'فحص اتصال الشبكة دون تغيير إعداداتها.',
          diagnosticCommands: ['ip a', 'ip route']);
      case ErrorType.missingDependency:
        return const RepairStrategy(description: 'تحديد الاعتمادية الناقصة. لا تثبيت آلي للحزم.',
          diagnosticCommands: ['pwd', 'ls -la']);
      case ErrorType.buildError:
        return const RepairStrategy(description: 'جمع تشخيص البناء؛ يحتاج إصلاح الكود إلى تحليل واعتماد تغييرات محددة.',
          diagnosticCommands: ['git status', 'git diff']);
      case ErrorType.storageFull:
        return const RepairStrategy(description: 'فحص المساحة فقط؛ لا حذف أو تنظيف تلقائي.',
          diagnosticCommands: ['df -h']);
      case ErrorType.outOfMemory:
        return const RepairStrategy(description: 'نفاد الذاكرة لا يعالج آلياً؛ أوقف المهمة وأبلغ المستخدم.',
          diagnosticCommands: ['free -h']);
      case ErrorType.unknown:
        return const RepairStrategy(description: 'خطأ غير معروف؛ أوقف الإصلاح الآلي واطلب مراجعة المستخدم.');
    }
  }
}
