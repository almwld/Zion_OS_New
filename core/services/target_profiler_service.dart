import 'dart:math';

class TargetProfiler {
  /// بناء ملف تعريفي للهدف
  static Map<String, dynamic> buildProfile({
    String? name,
    String? email,
    String? phone,
    String? company,
    String? position,
  }) {
    final profile = <String, dynamic>{
      'basic_info': {
        'name': name ?? 'Unknown',
        'email': email ?? 'Unknown',
        'phone': phone ?? 'Unknown',
        'company': company ?? 'Unknown',
        'position': position ?? 'Unknown',
      },
      'generated_info': {
        'estimated_age': _estimateAge(position),
        'tech_level': _assessTechLevel(position, company),
        'likely_passwords': _generateLikelyPasswords(name, company),
        'security_questions': _generateSecurityQuestions(name),
        'social_media_handles': _generateSocialHandles(name),
        'vulnerable_to': _assessVulnerabilities(position),
      },
      'attack_recommendations': [],
    };

    // توصيات هجومية مخصصة
    if ((profile['generated_info']['tech_level'] as String) == 'Low') {
      (profile['attack_recommendations'] as List).add('Phishing email with fake login page');
      (profile['attack_recommendations'] as List).add('USB drop attack');
    }
    if (position != null && position.toLowerCase().contains('ceo')) {
      (profile['attack_recommendations'] as List).add('Spear phishing with urgent business context');
      (profile['attack_recommendations'] as List).add('Whaling attack');
    }
    if (company != null) {
      (profile['attack_recommendations'] as List).add('Social engineering via LinkedIn');
      (profile['attack_recommendations'] as List).add('Target company VPN credentials');
    }

    return profile;
  }

  /// تقدير العمر
  static String _estimateAge(String? position) {
    if (position == null) return 'Unknown';
    final lower = position.toLowerCase();
    if (lower.contains('senior') || lower.contains('director') || lower.contains('vp')) return '40-55';
    if (lower.contains('junior') || lower.contains('intern')) return '20-30';
    if (lower.contains('ceo') || lower.contains('founder')) return '35-60';
    return '30-45';
  }

  /// تقييم المستوى التقني
  static String _assessTechLevel(String? position, String? company) {
    if (company != null && company.toLowerCase().contains('tech')) return 'High';
    if (position != null && position.toLowerCase().contains('it')) return 'High';
    if (position != null && position.toLowerCase().contains('engineer')) return 'High';
    if (position != null && position.toLowerCase().contains('manager')) return 'Medium';
    return 'Low';
  }

  /// توليد كلمات مرور محتملة
  static List<String> _generateLikelyPasswords(String? name, String? company) {
    final passwords = <String>[];
    if (name != null) {
      final parts = name.toLowerCase().split(' ');
      for (final part in parts) {
        passwords.add(part);
        passwords.add('$part${DateTime.now().year}');
        passwords.add('$part@${DateTime.now().year}');
        passwords.add('$part#1');
      }
    }
    if (company != null) {
      final comp = company.toLowerCase().replaceAll(' ', '');
      passwords.add(comp);
      passwords.add('$comp@${DateTime.now().year}');
      passwords.add('$comp#1');
    }
    passwords.addAll(['password', 'admin', 'welcome', 'letmein', 'changeme']);
    return passwords;
  }

  /// توليد أسئلة أمان محتملة
  static Map<String, String> _generateSecurityQuestions(String? name) {
    return {
      'Pet name': name != null ? '${name}Pet' : 'Unknown',
      'Mother maiden name': 'Smith',
      'Birth city': 'New York',
      'First school': 'Lincoln Elementary',
    };
  }

  /// توليد حسابات تواصل اجتماعي محتملة
  static List<String> _generateSocialHandles(String? name) {
    if (name == null) return [];
    final parts = name.toLowerCase().split(' ');
    final handles = <String>[];
    handles.add('@${parts.join('_')}');
    handles.add('@${parts.join('.')}');
    handles.add('@${parts.first}_official');
    return handles;
  }

  /// تقييم نقاط الضعف
  static List<String> _assessVulnerabilities(String? position) {
    final vulns = <String>['Phishing', 'Social engineering', 'Weak passwords'];
    if (position != null && position.toLowerCase().contains('executive')) {
      vulns.add('Whaling');
      vulns.add('Business email compromise');
    }
    if (position != null && position.toLowerCase().contains('hr')) {
      vulns.add('Resume-based malware');
    }
    return vulns;
  }
}
