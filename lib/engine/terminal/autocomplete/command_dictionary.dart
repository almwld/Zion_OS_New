class CommandInfo {
  const CommandInfo({required this.name,required this.description,this.subcommands=const {},this.parameters=const []});
  final String name,description;
  final Map<String,String> subcommands;
  final List<String> parameters;
}
class CommandDictionary {
  CommandDictionary():_commands={
    'git':const CommandInfo(name:'git',description:'نظام إدارة الإصدارات',subcommands:{
      'status':'عرض حالة المستودع','diff':'عرض الفروقات','log':'سجل الإصدارات','checkout':'الانتقال إلى فرع','cherry-pick':'انتقاء commit','check-ignore':'فحص التجاهل','add':'إضافة إلى staging','commit':'تسجيل تغييرات','branch':'إدارة الفروع','push':'رفع (محظور افتراضياً)','pull':'سحب'
    }),
    'flutter':const CommandInfo(name:'flutter',description:'أدوات Flutter',subcommands:{
      'analyze':'تحليل الكود','test':'تشغيل الاختبارات','pub get':'تحديث التبعيات','build apk':'بناء APK','build appbundle':'بناء AAB','clean':'تنظيف مخرجات البناء','doctor':'فحص البيئة'
    }),
    'dart':const CommandInfo(name:'dart',description:'أدوات Dart',subcommands:{'analyze':'تحليل','format':'تنسيق','run':'تشغيل'}),
    'apt':const CommandInfo(name:'apt',description:'إدارة الحزم (يتطلب موافقة)',subcommands:{'list':'عرض الحزم','show':'تفاصيل حزمة','install':'تثبيت (يتطلب موافقة)'}),
    'python3':const CommandInfo(name:'python3',description:'مفسر Python',subcommands:{'--version':'عرض الإصدار'}),
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
  List<String> get allCommands=>_commands.keys.toList(growable:false);
  String? describe(String command)=>_commands[command]?.description;
  List<String> subcommandsOf(String command)=>_commands[command]?.subcommands.keys.toList(growable:false)??const [];
  Future<List<String>> suggestParameters(String command,String currentArg,Map context) async {
    if(command=='git'&&(currentArg.isEmpty||'checkout'.startsWith(currentArg)||'branch'.startsWith(currentArg))){
      final branches=(context['branches'] as List?)?.map((e)=>e.toString()).toList()??const <String>[];
      return [...subcommandsOf('git'),...branches].where((e)=>e.startsWith(currentArg)).toSet().toList();
    }
    return subcommandsOf(command).where((e)=>e.startsWith(currentArg)).toList();
  }
}
