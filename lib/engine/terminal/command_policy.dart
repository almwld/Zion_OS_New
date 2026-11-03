class PolicyResult {
  const PolicyResult(this.allowed,{this.requiresApproval=false,this.reason});
  final bool allowed;
  final bool requiresApproval;
  final String? reason;
  factory PolicyResult.allow({bool approval=false})=>PolicyResult(true,requiresApproval:approval);
  factory PolicyResult.deny(String reason)=>PolicyResult(false,reason:reason);
}

class CommandPolicy {
  const CommandPolicy();
  static const allowedCommands=<String>{
    'ls','cat','grep','find','wc','head','tail','echo','pwd','whoami','id','uname','df','free','ps','ip','ss','netstat','lsof','which','command','type','file',
    'git status','git diff','git log','git branch','git add','git commit','git checkout','git cherry-pick','git check-ignore',
    'flutter analyze','flutter test','flutter pub get','flutter build apk','flutter build appbundle','flutter clean','flutter doctor',
    'dart analyze','dart format','python3','apt list','apt show','apt install','adb devices','adb version'
  };
  static const allowedWithApproval=<String>{
    'git add','git commit','git checkout','git cherry-pick','apt install','flutter build apk','flutter build appbundle','dart format'
  };
  static final RegExp _dangerousChars=RegExp(r'[|&;<>$(){}\[\]\\\x60\n\r]');

  PolicyResult check(String command) {
    final value=command.trim();
    if(value.isEmpty||value.length>2000)return PolicyResult.deny('الأمر فارغ أو يتجاوز 2000 محرف.');
    if(value.contains('\u0000')||value.contains('\n')||value.contains('\r'))return PolicyResult.deny('الأسطر المتعددة غير مسموحة.');
    final commitMessage=value.startsWith('git commit -m ')&&_validQuotedCommit(value);
    if((value.contains('`')||_dangerousChars.hasMatch(value))&&!commitMessage)return PolicyResult.deny('يحتوي الأمر على محارف shell خطرة.');
    final tokens=value.split(RegExp(r'\s+')).where((e)=>e.isNotEmpty).toList();
    if(tokens.isEmpty)return PolicyResult.deny('تعذر تحليل الأمر.');
    final key=_commandKey(tokens);
    if(!allowedCommands.contains(key))return PolicyResult.deny('الأمر أو مجموعة الأوامر غير موجودة في القائمة البيضاء: $key');
    if(tokens.any((t)=>t=='..'||t.contains('../')||t.contains('/..')))return PolicyResult.deny('المسار يتضمن انتقالاً خارج المجلد.');
    if(tokens.any((t)=>t.startsWith('/etc/')||const {'sudo','su','rm','mv','dd','mkfs','shred'}.contains(t)))return PolicyResult.deny('العملية محظورة.');
    if(tokens.first=='apt'&&tokens.length>1&&tokens[1]=='install'&&(tokens.length<3||tokens.length>4||tokens.skip(2).any((t)=>t.startsWith('-'))))return PolicyResult.deny('يسمح بتثبيت حزمة محددة فقط بعد الموافقة.');\n    if(tokens.first=='git'&&tokens.length>1&&tokens[1]=='checkout'&&(tokens.length!=3||tokens[2].startsWith('-')))return PolicyResult.deny('يسمح بالانتقال إلى فرع مسمى فقط وبعد الموافقة.');\n    if(tokens.first=='git'&&tokens.length>1&&tokens[1]=='cherry-pick'&&(tokens.length!=3||!RegExp(r'^[a-fA-F0-9]{7,40}&&(tokens.length!=3||tokens[1]!='-v'))return PolicyResult.deny('يسمح فقط بالأمر command -v.');
    if(tokens.first=='python3'&&!(tokens.length==2&&tokens[1]=='--version'))return PolicyResult.deny('تشغيل سكربتات Python غير متاح عبر الطرفية العامة.');
    if(tokens.first=='ip') {
      if(tokens.length<2||!const {'a','addr','route'}.contains(tokens[1]))return PolicyResult.deny('يسمح فقط باستعلامات ip للقراءة.');
      if(tokens.length>2&&!(tokens[1]=='route'&&const {'show','list'}.contains(tokens[2])))return PolicyResult.deny('خيارات ip غير القرائية محظورة.');
      if(tokens.skip(2).any((t)=>const {'add','del','delete','replace','flush','change'}.contains(t)))return PolicyResult.deny('تغيير إعدادات الشبكة محظور.');
    }
    if(tokens.first=='git'&&tokens.length>2&&tokens[1]=='add'&&tokens.skip(2).any((t)=>const {'.','-A','--all'}.contains(t)))return PolicyResult.deny('git add . و--all غير مسموحين؛ حدّد الملفات صراحة.');
    if(tokens.first=='find'&&tokens.any((t)=>const {'-exec','-execdir','-delete','-ok','-okdir'}.contains(t)))return PolicyResult.deny('عمليات find التي تنفذ أو تحذف ملفات محظورة.');
    if(tokens.first=='git'&&tokens.length>2) {
      final args=tokens.skip(2);
      if(tokens[1]=='branch'&&args.any((t)=>const {'-d','-D','-m','-M','-c','-C'}.contains(t)))return PolicyResult.deny('تعديل الفروع محظور من سير العمل التلقائي.');
      if((tokens[1]=='diff'||tokens[1]=='log')&&args.any((t)=>t=='--output'||t.startsWith('--output=')))return PolicyResult.deny('كتابة مخرجات Git إلى ملف غير مسموحة.');
    }
    if(tokens.first=='ps'&&tokens.skip(1).any((t)=>t.startsWith('-')&&!const {'-a','-u','-x','-ef'}.contains(t)))return PolicyResult.deny('خيارات ps غير معتمدة.');
    return PolicyResult.allow(approval:allowedWithApproval.contains(key));
  }

  String _commandKey(List<String> tokens) {
    if(tokens.first=='git'&&tokens.length>1)return 'git ${tokens[1]}';
    if(tokens.first=='flutter'&&tokens.length>1) {
      if(tokens[1]=='build'&&tokens.length>2)return 'flutter build ${tokens[2]}';
      if(tokens[1]=='pub'&&tokens.length>2)return 'flutter pub ${tokens[2]}';
      return 'flutter ${tokens[1]}';
    }
    if(tokens.first=='dart'&&tokens.length>1)return 'dart ${tokens[1]}';\n    if(tokens.first=='apt'&&tokens.length>1)return 'apt ${tokens[1]}';\n    if(tokens.first=='adb'&&tokens.length>1)return 'adb ${tokens[1]}';
    return tokens.first;
  }

  bool _validQuotedCommit(String value)=>RegExp(r'''^git commit -m "[A-Za-z0-9 _.,:!?()\-]{1,200}"$''').hasMatch(value);
}
).hasMatch(tokens[2])))return PolicyResult.deny('يسمح بانتقاء commit SHA محدد فقط وبعد الموافقة.');\n    if(tokens.first=='adb'&&!(tokens.length==2&&const {'devices','version'}.contains(tokens[1])))return PolicyResult.deny('يسمح فقط باستعلامات adb للقراءة.');\n    if(tokens.first=='flutter'&&tokens.length>1&&tokens[1]=='clean'&&tokens.length!=2)return PolicyResult.deny('flutter clean لا يقبل معاملات إضافية.');\n    if(tokens.first=='command'&&(tokens.length!=3||tokens[1]!='-v'))return PolicyResult.deny('يسمح فقط بالأمر command -v.');
    if(tokens.first=='python3'&&!(tokens.length==2&&tokens[1]=='--version'))return PolicyResult.deny('تشغيل سكربتات Python غير متاح عبر الطرفية العامة.');
    if(tokens.first=='ip') {
      if(tokens.length<2||!const {'a','addr','route'}.contains(tokens[1]))return PolicyResult.deny('يسمح فقط باستعلامات ip للقراءة.');
      if(tokens.length>2&&!(tokens[1]=='route'&&const {'show','list'}.contains(tokens[2])))return PolicyResult.deny('خيارات ip غير القرائية محظورة.');
      if(tokens.skip(2).any((t)=>const {'add','del','delete','replace','flush','change'}.contains(t)))return PolicyResult.deny('تغيير إعدادات الشبكة محظور.');
    }
    if(tokens.first=='git'&&tokens.length>2&&tokens[1]=='add'&&tokens.skip(2).any((t)=>const {'.','-A','--all'}.contains(t)))return PolicyResult.deny('git add . و--all غير مسموحين؛ حدّد الملفات صراحة.');
    if(tokens.first=='find'&&tokens.any((t)=>const {'-exec','-execdir','-delete','-ok','-okdir'}.contains(t)))return PolicyResult.deny('عمليات find التي تنفذ أو تحذف ملفات محظورة.');
    if(tokens.first=='git'&&tokens.length>2) {
      final args=tokens.skip(2);
      if(tokens[1]=='branch'&&args.any((t)=>const {'-d','-D','-m','-M','-c','-C'}.contains(t)))return PolicyResult.deny('تعديل الفروع محظور من سير العمل التلقائي.');
      if((tokens[1]=='diff'||tokens[1]=='log')&&args.any((t)=>t=='--output'||t.startsWith('--output=')))return PolicyResult.deny('كتابة مخرجات Git إلى ملف غير مسموحة.');
    }
    if(tokens.first=='ps'&&tokens.skip(1).any((t)=>t.startsWith('-')&&!const {'-a','-u','-x','-ef'}.contains(t)))return PolicyResult.deny('خيارات ps غير معتمدة.');
    return PolicyResult.allow(approval:allowedWithApproval.contains(key));
  }

  String _commandKey(List<String> tokens) {
    if(tokens.first=='git'&&tokens.length>1)return 'git ${tokens[1]}';
    if(tokens.first=='flutter'&&tokens.length>1) {
      if(tokens[1]=='build'&&tokens.length>2)return 'flutter build ${tokens[2]}';
      if(tokens[1]=='pub'&&tokens.length>2)return 'flutter pub ${tokens[2]}';
      return 'flutter ${tokens[1]}';
    }
    if(tokens.first=='dart'&&tokens.length>1)return 'dart ${tokens[1]}';
    return tokens.first;
  }

  bool _validQuotedCommit(String value)=>RegExp(r'''^git commit -m "[A-Za-z0-9 _.,:!?()\-]{1,200}"$''').hasMatch(value);
}
