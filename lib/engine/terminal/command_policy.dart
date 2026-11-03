class PolicyResult {
  const PolicyResult(this.allowed, {this.requiresApproval = false, this.reason});
  final bool allowed;
  final bool requiresApproval;
  final String? reason;
  factory PolicyResult.allow({bool approval = false}) => PolicyResult(true, requiresApproval: approval);
  factory PolicyResult.deny(String reason) => PolicyResult(false, reason: reason);
}

class CommandPolicy {
  static const allowedCommands = <String>{
    'ls','cat','grep','find','wc','head','tail','echo','pwd','whoami','id','uname','df','free','ps','ip','ss','netstat','lsof','which','command','type','file',
    'git status','git diff','git log','git branch','git add','git commit',
    'flutter analyze','flutter test','flutter pub get','flutter build apk','flutter build appbundle',
    'dart analyze','dart format','python3'
  };
  static const allowedWithApproval = <String>{
    'git add','git commit','flutter build apk','flutter build appbundle','dart format'
  };
  static final RegExp _dangerousChars = RegExp(r'[|&;<>\$(){}\[\]\\\x60\n\r]');
  static final RegExp _token = RegExp(r'''^(?:[A-Za-z0-9_./:@%+=,-]+|"[^"\n]*"|'[^'\n]*')$''');

  PolicyResult check(String command) {
    final value = command.trim();
    if (value.isEmpty || value.length > 2000) return PolicyResult.deny('الأمر فارغ أو يتجاوز 2000 محرف.');
    if (value.contains('\u0000') || value.contains('\n') || value.contains('\r')) return PolicyResult.deny('الأسطر المتعددة غير مسموحة.');
    final commitMessage = value.startsWith('git commit -m ') && _validQuotedCommit(value);
    if (_dangerousChars.hasMatch(value) && !commitMessage) return PolicyResult.deny('يحتوي الأمر على محارف shell خطرة.');
    final tokens = _split(value);
    if (tokens.isEmpty) return PolicyResult.deny('تعذر تحليل الأمر.');
    final commandKey = _commandKey(tokens);
    if (!allowedCommands.contains(commandKey)) return PolicyResult.deny('الأمر أو مجموعة الأوامر غير موجودة في القائمة البيضاء: $commandKey');
    if (tokens.any((t) => t == '..' || t.contains('../') || t.contains('/..'))) return PolicyResult.deny('المسار يتضمن انتقالاً خارج المجلد.');
    if (tokens.any((t) => t.startsWith('/etc/') || t == 'sudo' || t == 'su' || t == 'rm' || t == 'mv' || t == 'dd' || t == 'mkfs' || t == 'shred')) {
      return PolicyResult.deny('العملية محظورة.');
    }
    return PolicyResult.allow(approval: allowedWithApproval.contains(commandKey));
  }

  List<String> _split(String value) => value.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  String _commandKey(List<String> t) {
    if (t.first == 'git' && t.length > 1) return 'git ${t[1]}';
    if (t.first == 'flutter' && t.length > 1) {
      if (t[1] == 'build' && t.length > 2) return 'flutter build ${t[2]}';
      if (t[1] == 'pub' && t.length > 2) return 'flutter pub ${t[2]}';
      return 'flutter ${t[1]}';
    }
    if (t.first == 'dart' && t.length > 1) return 'dart ${t[1]}';
    return t.first;
  }
  bool _validQuotedCommit(String value) {
    final match = RegExp(r'''^git commit -m "(?:[^"\\]|\\.){1,200}"$''').firstMatch(value);
    return match != null;
  }
}
