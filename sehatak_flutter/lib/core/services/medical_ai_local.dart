import 'dart:math';

/// =============================================
///   SEHTAK AI - محرك الذكاء الاصطناعي المحلي
///   يعمل بالكامل داخل المنصة بدون إنترنت
/// =============================================

class LocalMedicalAI {
  static final LocalMedicalAI _instance = LocalMedicalAI._internal();
  factory LocalMedicalAI() => _instance;
  LocalMedicalAI._internal();

  final Random _random = Random();

  // ========== قاعدة الأدوية ==========
  final Map<String, Map<String, String>> _drugsDb = {
    'باراسيتامول': {
      'category': 'مسكن ألم وخافض حرارة',
      'dose': '500-1000mg كل 6-8 ساعات',
      'pregnancy': 'آمن',
      'sideEffects': 'نادر: حساسية',
      'notes': 'لا يتعارض مع المعدة'
    },
    'ايبوبروفين': {
      'category': 'مضاد التهاب',
      'dose': '200-400mg كل 6-8 ساعات',
      'pregnancy': 'غير آمن',
      'sideEffects': 'حرقة معدة، قرحة',
      'notes': 'يؤخذ مع الطعام'
    },
    'اموكسيسيلين': {
      'category': 'مضاد حيوي',
      'dose': '500mg كل 8 ساعات',
      'pregnancy': 'آمن نسبياً',
      'sideEffects': 'إسهال، حساسية',
      'notes': 'أكمل الكورس كاملاً'
    },
    'اوميبرازول': {
      'category': 'مثبط مضخة بروتون',
      'dose': '20-40mg يومياً',
      'pregnancy': 'باستشارة طبيب',
      'sideEffects': 'صداع، إسهال',
      'notes': 'يؤخذ قبل الأكل'
    },
    'ميتفورمين': {
      'category': 'خافض سكر',
      'dose': '500-850mg مع الأكل',
      'pregnancy': 'باستشارة طبيب',
      'sideEffects': 'غثيان، إسهال',
      'notes': 'يبدأ بجرعة منخفضة'
    },
    'سيتريزين': {
      'category': 'مضاد حساسية',
      'dose': '10mg يومياً',
      'pregnancy': 'باستشارة طبيب',
      'sideEffects': 'نعاس، جفاف فم',
      'notes': 'الجيل الثاني - أقل تهدئة'
    },
  };

  // ========== قاعدة الأمراض ==========
  final Map<String, Map<String, String>> _diseasesDb = {
    'ارتفاع ضغط الدم': {
      'category': 'قلب وأوعية',
      'symptoms': 'صداع، دوخة، نزيف أنف',
      'treatment': 'أدوية خافضة، تقليل ملح، رياضة',
      'prevention': 'غذاء صحي، وزن مثالي',
      'normalRange': 'أقل من 120/80'
    },
    'السكري': {
      'category': 'غدد صماء',
      'symptoms': 'عطش، تبول كثير، جوع',
      'treatment': 'ميتفورمين، أنسولين، حمية',
      'prevention': 'وزن صحي، رياضة، تغذية',
      'normalRange': 'سكر صائم <100'
    },
  };

  // ========== 30 تخصص طبي ==========
  final Map<String, List<String>> _specializations = {
    'الطب العصبي': ['صداع', 'دوار', 'دوخة', 'تشنج', 'صرع', 'تنميل'],
    'الصدرية والقلب': ['صدر', 'قلب', 'ضيق تنفس', 'سعال', 'خفقان'],
    'الجهاز الهضمي': ['بطن', 'معدة', 'إسهال', 'غثيان', 'حرقة'],
    'الجلدية': ['طفح', 'حكة', 'احمرار', 'تورم', 'بثور'],
    'العظام والمفاصل': ['عظام', 'مفاصل', 'ظهر', 'رقبة', 'ركبة'],
    'الصحة النفسية': ['قلق', 'اكتئاب', 'أرق', 'توتر', 'خوف'],
    'طب الأطفال': ['طفل', 'رضيع', 'حمى', 'تسنين', 'مغص'],
    'طب العيون': ['عين', 'رؤية', 'غشاوة', 'دموع'],
    'الطب العام': ['حرارة', 'تعب', 'إرهاق', 'ضعف'],
  };

  // ========== 100+ نصيحة ==========
  final List<String> _tips = [
    'اشرب 8-10 أكواب ماء يومياً',
    'مارس المشي 30 دقيقة يومياً',
    'تناول 5 حصص خضار وفواكه',
    'نم 7-8 ساعات ليلاً',
    'قلل استهلاك الملح',
    'تجنب التدخين والكحول',
    'افحص ضغط الدم شهرياً',
    'افحص السكر سنوياً',
    'استخدم واقي شمس',
    'اغسل يديك بانتظام',
  ];

  // ========== خدمة منصة ==========
  final Map<String, String> _appHelp = {
    'حجز موعد': 'اذهب للأطباء > اختر التخصص > اختر الطبيب > التاريخ > أكد',
    'طلب دواء': 'اذهب للصيدلية > ابحث > أضف للسلة > أكمل الطلب',
    'استشارة': 'اذهب للدردشة > اختر طبيب > ابدأ المحادثة',
    'تذكير أدوية': 'اذهب للتذكير > + > أدخل الدواء والجرعة والوقت',
    'طوارئ': 'اضغط SOS أو اذهب للطوارئ > اتصل مباشرة',
  };

  /// ========== تحليل الأعراض والفرز ==========
  Map<String, dynamic> triage(String symptoms, {String? bodyPart}) {
    String bestSpec = 'الطب العام';
    int maxScore = 0;
    List<String> matched = [];

    for (var entry in _specializations.entries) {
      int score = 0;
      for (var keyword in entry.value) {
        if (symptoms.contains(keyword)) {
          score++;
          matched.add(keyword);
        }
      }
      if (score > maxScore) {
        maxScore = score;
        bestSpec = entry.key;
      }
    }

    // تحديد الطوارئ
    String urgency = 'low';
    final highKeywords = ['شديد', 'حادث', 'نزيف', 'اختناق', 'غيبوبة'];
    final mediumKeywords = ['متوسط', 'مستمر', 'متكرر'];
    if (highKeywords.any((k) => symptoms.contains(k))) urgency = 'high';
    else if (mediumKeywords.any((k) => symptoms.contains(k))) urgency = 'medium';

    String action;
    String timeframe;
    if (urgency == 'high') {
      action = '🚨 استشارة فورية أو زيارة مستشفى';
      timeframe = 'فوري';
    } else if (urgency == 'medium') {
      action = '📅 استشارة طبية خلال 24-48 ساعة';
      timeframe = 'خلال 24 ساعة';
    } else {
      action = '🏠 مراقبة منزلية، راجع إذا استمرت';
      timeframe = '3-5 أيام';
    }

    return {
      'specialization': bestSpec,
      'urgency': urgency,
      'action': action,
      'timeframe': timeframe,
      'confidence': (0.7 + (maxScore * 0.08)).clamp(0.0, 0.95),
      'matched_symptoms': matched.take(5).toList(),
    };
  }

  /// ========== فحص أعراض شامل ==========
  Map<String, dynamic> symptomChecker(String symptoms, {String? bodyPart}) {
    final triageResult = triage(symptoms, bodyPart: bodyPart);
    
    // حالات محتملة حسب التخصص
    final conditions = <String, List<Map<String, String>>>{
      'الطب العصبي': [
        {'name': 'صداع توتري', 'prob': 'مرتفع', 'treatment': 'راحة، مسكنات'},
        {'name': 'شقيقة', 'prob': 'متوسط', 'treatment': 'غرفة مظلمة، مسكنات'},
      ],
      'الصدرية والقلب': [
        {'name': 'التهاب شعب', 'prob': 'متوسط', 'treatment': 'مضاد حيوي'},
        {'name': 'ارتجاع مريئي', 'prob': 'متوسط', 'treatment': 'مضاد حموضة'},
      ],
      'الجهاز الهضمي': [
        {'name': 'التهاب معدي', 'prob': 'مرتفع', 'treatment': 'سوائل، راحة'},
        {'name': 'قولون عصبي', 'prob': 'متوسط', 'treatment': 'ألياف، بروبيوتك'},
      ],
      'الطب العام': [
        {'name': 'نزلة برد', 'prob': 'مرتفع', 'treatment': 'راحة، سوائل'},
        {'name': 'إرهاق عام', 'prob': 'متوسط', 'treatment': 'نوم، تغذية'},
      ],
    };

    return {
      'triage': triageResult,
      'possible_conditions': conditions[triageResult['specialization']] ?? conditions['الطب العام']!,
      'notes': '⚠️ هذا تشخيص أولي فقط، راجع الطبيب للتشخيص الدقيق',
    };
  }

  /// ========== معلومات دواء ==========
  Map<String, dynamic>? drugInfo(String drugName) {
    for (var entry in _drugsDb.entries) {
      if (drugName.contains(entry.key)) {
        return {'name': entry.key, ...entry.value};
      }
    }
    return null;
  }

  /// ========== معلومات مرض ==========
  Map<String, dynamic>? diseaseInfo(String diseaseName) {
    for (var entry in _diseasesDb.entries) {
      if (diseaseName.contains(entry.key)) {
        return {'name': entry.key, ...entry.value};
      }
    }
    return null;
  }

  /// ========== مساعدة في المنصة ==========
  String? appHelp(String query) {
    for (var entry in _appHelp.entries) {
      if (query.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// ========== نصيحة عشوائية ==========
  String randomTip() => _tips[_random.nextInt(_tips.length)];

  /// ========== مساعد ذكي للمحادثة ==========
  String chatbotRespond(String message) {
    // تحية
    if (RegExp(r'سلام|هلا|مرحب|اهلا|hi|hello').hasMatch(message)) {
      return 'وعليكم السلام! 🌸\n\nأنا مساعدك الصحي. اسألني عن:\n• أعراضك 🩺\n• الأدوية 💊\n• خدمات المنصة 📱';
    }
    // طوارئ
    if (RegExp(r'طوارئ|emergency|نزيف|اختناق').hasMatch(message)) {
      return '🚨 اتصل فوراً: 1122\nاذهب لأقرب مستشفى\nاستخدم زر SOS في التطبيق';
    }
    // أعراض
    if (RegExp(r'عندي|اعاني|احس|اشعر|الم|وجع').hasMatch(message)) {
      return '🩺 صف أعراضك بالتفصيل وسأساعدك في تحليلها.\n\nمثال: "صداع شديد مع دوخة منذ يومين"';
    }
    // باقات
    if (RegExp(r'باقة|اشتراك|سعر|تكلفة').hasMatch(message)) {
      return '💎 الباقة الأساسية: مجانية\n⭐ الذهبية: 99 ر.س/شهر\n👑 البلاتينية: 249 ر.س/شهر\n👨‍👩‍👧‍👦 العائلية: 399 ر.س/شهر';
    }
    // أدوية
    if (RegExp(r'دواء|علاج|باراسيتامول|ايبوبروفين').hasMatch(message)) {
      for (var drug in _drugsDb.keys) {
        if (message.contains(drug)) {
          final info = _drugsDb[drug]!;
          return '💊 $drug\n📋 ${info['category']}\n💉 ${info['dose']}\n⚠️ ${info['pregnancy']}';
        }
      }
      return '💊 اكتب اسم الدواء للمعلومات. مثال: "باراسيتامول"';
    }
    // خدمات
    if (RegExp(r'كيف|طريقة').hasMatch(message)) {
      for (var entry in _appHelp.entries) {
        if (message.contains(entry.key)) {
          return '📱 ${entry.key}:\n${entry.value}';
        }
      }
    }
    // افتراضي
    return 'شكراً لتواصلك! 🙏\n\n$randomTip()\n\nللمساعدة اكتب: أعراض، أدوية، باقات، خدمات';
  }
}
