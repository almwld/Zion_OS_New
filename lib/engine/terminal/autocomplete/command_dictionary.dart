class CommandInfo {
  const CommandInfo({required this.name,required this.description,this.subcommands=const {},this.parameters=const []});
  final String name,description;
  final Map<String,String> subcommands;
  final List<String> parameters;
}
class CommandDictionary {
  CommandDictionary():_commands={
    'git':const CommandInfo(name:'git',description:'نظام إدارة الإصدارات',subcommands:{
      'status':'عرض حالة المستودع','diff':'عرض الفروقات','log':'سجل الإصدارات','checkout':'الانتقال إلى فرع (يتطلب موافقة)','cherry-pick':'انتقاء commit (يتطلب موافقة)','check-ignore':'فحص التجاهل','add':'إضافة إلى staging (يتطلب موافقة)','commit':'تسجيل تغييرات (يتطلب موافقة)','branch':'إدارة الفروع'
    }),
    'flutter':const CommandInfo(name:'flutter',description:'أدوات Flutter',subcommands:{
      'analyze':'تحليل الكود','test':'تشغيل الاختبارات','pub get':'تحديث التبعيات','build apk':'بناء APK (يتطلب موافقة)','build appbundle':'بناء AAB (يتطلب موافقة)','clean':'تنظيف مخرجات البناء','doctor':'فحص البيئة'
    }),
    'dart':const CommandInfo(name:'dart',description:'أدوات Dart',subcommands:{'analyze':'تحليل','format':'تنسيق (يتطلب موافقة)'}),
    'apt':const CommandInfo(name:'apt',description:'إدارة الحزم (التثبيت يتطلب موافقة)',subcommands:{'list':'عرض الحزم','show':'تفاصيل حزمة','install':'تثبيت (يتطلب موافقة)'}),
    'python3':const CommandInfo(name:'python3',description:'مفسر Python؛ عرض الإصدار فقط من القائمة العامة',subcommands:{'--version':'عرض الإصدار'}),
    'adb':const CommandInfo(name:'adb',description:'Android Debug Bridge',subcommands:{'devices':'الأجهزة','version':'الإصدار'}),
    'ls':const CommandInfo(name:'ls',description:'عرض الملفات'),
    'cat':const CommandInfo(name:'cat',description:'قراءة ملف'),
    'grep':const CommandInfo(name:'grep',description:'البحث داخل النصوص'),
    'find':const CommandInfo(name:'find',description:'البحث عن الملفات'),
    'pwd':const CommandInfo(name:'pwd',description:'المجلد الحالي'),
    'whoami':const CommandInfo(name:'whoami',description:'المستخدم الحالي'),
    'which':const CommandInfo(name:'which',description:'تحديد مسار الأمر')
  };
  final Map<String,CommandInfo> _commands;
  List<String> get allCommands=>const [
    'ls','cat','grep','find','wc','head','tail','echo','pwd','whoami','id','uname','df','free','ps','ip a','ip addr','ip route','ss','netstat','lsof','which','type','file',
    'git status','git diff','git log','git branch','git add','git commit','git checkout','git cherry-pick','git check-ignore',
    'flutter analyze','flutter test','flutter pub get','flutter build apk','flutter build appbundle','flutter clean','flutter doctor',
    'dart analyze','dart format','python3 --version','apt list','apt show','apt install','adb devices','adb version'
  ];
  String? describe(String command)=>_commands[command]?.description;
  List<String> subcommandsOf(String command)=>_commands[command]?.subcommands.keys.toList(growable:false)??const [];
  Future<List<String>> suggestParameters(String command,String currentArg,Map context) async {
    if(command=='git'&&context['subcommand']=='checkout') {
      final branches=(context['branches'] as List?)?.map((e)=>e.toString()).toList()??const <String>[];
      return branches.where((e)=>e.startsWith(currentArg)).toList();
    }
    return subcommandsOf(command).where((e)=>e.startsWith(currentArg)).toList();
  }
}
