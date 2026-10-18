/// Command gate for Zion Agent Loop.
///
/// The agent may use the terminal's normal shell toolchain instead of a tiny
/// hard-coded reconnaissance allow-list. The visible approval dialog and Stop
/// control remain the user's execution controls; this class only rejects
/// clearly destructive host-level patterns and malformed/oversized input.
class AgentLoopValidator {
  const AgentLoopValidator();

  bool validTarget(String value) {
    // This field is now a task description, not a network target.
    final task = value.trim();
    return task.isNotEmpty && task.length <= 2000;
  }

  String? validateCommand(String command, String task) {
    final value = command.trim();
    if (value.isEmpty) return 'النموذج لم يُرجع أمراً.';
    if (value.length > 4000) return 'الأمر طويل جداً (الحد 4000 محرف).';
    if (value.contains('\u0000')) return 'الأمر يحتوي على محرف غير صالح.';

    // Do not silently allow common catastrophic filesystem/device wipes.
    // Other normal shell commands, pipes, redirects, scripts and package
    // managers are allowed; the UI still exposes the exact command before run.
    final lower = value.toLowerCase();
    final criticalPatterns = <RegExp>[
      RegExp(r'(^|\s)rm\s+(-[^\s]*\s+)*(-rf|-fr|--recursive).*\s(/|/data|/system|/storage)(\s|$)'),
      RegExp(r'(^|\s)mkfs(?:\.[a-z0-9]+)?\s'),
      RegExp(r'(^|\s)dd\s+.*\bof=/dev/(block/)?(mmcblk|sda|nvme|dm-)'),
      RegExp(r'(^|\s)(reboot|poweroff|shutdown)\s*(?:-f|--force)'),
      RegExp(r':\s*\(\s*\)\s*\{\s*:'),
    ];
    if (criticalPatterns.any((pattern) => pattern.hasMatch(value))) {
      return 'أُوقف أمر قد يمسح بيانات أو يغيّر أقسام الجهاز بشكل كارثي.';
    }
    if (lower.contains('su -c') || lower.contains('sudo rm -rf /')) {
      return 'يتطلب الأمر تصعيداً أو يتضمن حذفاً خطيراً؛ نفّذه يدوياً بعد مراجعة مستقلة.';
    }
    return null;
  }
}
