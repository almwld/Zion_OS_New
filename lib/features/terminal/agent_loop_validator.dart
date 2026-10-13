/// Input validation for the bounded Zion Agent Loop reconnaissance tools.
/// This validates a single command line before it reaches TerminalService.
class AgentLoopValidator {
  const AgentLoopValidator();

  static const allowedTools = <String>{
    'nmap', 'whois', 'dig', 'nslookup', 'ping', 'traceroute',
    'curl', 'whatweb', 'nikto',
  };

  bool validTarget(String value) {
    final target = value.trim();
    if (target.isEmpty || target.length > 253 ||
        target.contains('/') || target.contains(' ') ||
        target.contains('@') || target.contains(':')) {
      return false;
    }
    final ipv4 = RegExp(r'^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$');
    final hostname = RegExp(
      r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\\.?$',
    );
    if (ipv4.hasMatch(target)) {
      return target.split('.').every(
        (part) => int.tryParse(part) != null && int.parse(part) <= 255,
      );
    }
    return hostname.hasMatch(target);
  }

  String? validateCommand(String command, String target) {
    final value = command.trim();
    if (value.isEmpty || value.length > 500) {
      return 'الأمر فارغ أو طويل أكثر من اللازم.';
    }
    if (RegExp(r'[;|&\\x60\\$<>\\n\\r]').hasMatch(value)) {
      return 'الأمر يحتوي على تركيب shell مركب وغير مدعوم في Agent Loop.';
    }

    final parts = value.split(RegExp(r'\\s+'));
    final base = parts.first.split('/').last.toLowerCase();
    if (!allowedTools.contains(base)) {
      return 'الأداة غير مفعّلة في قائمة أدوات Agent Loop: $base';
    }
    if (!_referencesExactTarget(parts, target)) {
      return 'يجب أن يشير الأمر إلى الهدف المحدد نفسه ($target)، لا إلى نطاق مشابه.';
    }

    final lower = value.toLowerCase();
    if (RegExp(r'(^|\\s)(--script|-o[a-z]*|--output|--data|--upload-file|--request|--config|--proxy|--connect-to|--resolve)(\\s|=|$)').hasMatch(lower)) {
      return 'خيارات السكربت/الإخراج/الإرسال غير مفعّلة في Agent Loop.';
    }
    if (RegExp(r'(^|\\s)(-a|-sc|-su|-p-|-x|-d|-t|-o|-k)(\\s|$)').hasMatch(lower) ||
        RegExp(r'\\b(--insecure|--force-ssl|--auth|--password|--user)\\b').hasMatch(lower)) {
      return 'الخيار غير مدعوم في وضع الاستطلاع المحدود.';
    }
    if (base == 'nmap' &&
        RegExp(r'(^|\\s)-p\\s*(?:1-65535|0-65535|-)(\\s|$)').hasMatch(lower)) {
      return 'يجب تحديد مجموعة منافذ محدودة بدلاً من فحص جميع المنافذ.';
    }
    if (base == 'curl' &&
        !RegExp(r'^curl\\s+(?:-sS\\s+)?-I\\s+https?://', caseSensitive: false).hasMatch(value)) {
      return 'curl متاح لطلبات HEAD فقط في Agent Loop.';
    }
    return null;
  }

  bool _referencesExactTarget(List<String> parts, String target) {
    final normalizedTarget = _normalizeHost(target);
    for (final raw in parts.skip(1)) {
      final token = raw.replaceAll(RegExp(r'''^["']|["']$'''), '');
      if (token.isEmpty) continue;
      if (token.toLowerCase().startsWith('http://') ||
          token.toLowerCase().startsWith('https://')) {
        final uri = Uri.tryParse(token);
        if (uri != null && uri.hasAuthority &&
            _normalizeHost(uri.host) == normalizedTarget) {
          return true;
        }
      } else if (_normalizeHost(token) == normalizedTarget) {
        return true;
      }
    }
    return false;
  }

  String _normalizeHost(String host) {
    var value = host.trim().toLowerCase();
    while (value.endsWith('.')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
