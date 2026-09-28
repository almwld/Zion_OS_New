import 'dart:math';

class SocialEngineerToolkit {
  /// إنشاء صفحة تصيد (Phishing Page)
  static String generatePhishingPage(String targetSite) {
    final templates = {
      'google': '''
<div style="text-align:center; margin-top:100px;">
  <img src="https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png">
  <h2 style="color:#333; font-family:sans-serif;">Sign in</h2>
  <p style="color:#666;">to continue to Gmail</p>
  <input type="email" placeholder="Email or phone" style="width:300px; padding:10px; margin:5px; border:1px solid #ccc; border-radius:4px;"><br>
  <input type="password" placeholder="Password" style="width:300px; padding:10px; margin:5px; border:1px solid #ccc; border-radius:4px;"><br>
  <button style="background:#1a73e8; color:white; padding:10px 30px; border:none; border-radius:4px; cursor:pointer;">Next</button>
</div>''',
      'facebook': '''
<div style="text-align:center; margin-top:50px; background:#f0f2f5; padding:20px;">
  <h1 style="color:#1877f2; font-size:40px;">facebook</h1>
  <div style="background:white; padding:20px; border-radius:8px; width:350px; margin:auto;">
    <input type="text" placeholder="Email address or phone number" style="width:100%; padding:10px; margin:5px 0; border:1px solid #ddd; border-radius:6px;"><br>
    <input type="password" placeholder="Password" style="width:100%; padding:10px; margin:5px 0; border:1px solid #ddd; border-radius:6px;"><br>
    <button style="background:#1877f2; color:white; width:100%; padding:10px; border:none; border-radius:6px; font-size:18px;">Log In</button>
  </div>
</div>''',
      'instagram': '''
<div style="text-align:center; margin-top:30px;">
  <h1 style="font-family:cursive; font-size:40px;">Instagram</h1>
  <div style="border:1px solid #dbdbdb; width:350px; margin:auto; padding:20px;">
    <input type="text" placeholder="Phone number, username, or email" style="width:100%; padding:8px; margin:3px 0; background:#fafafa; border:1px solid #dbdbdb;"><br>
    <input type="password" placeholder="Password" style="width:100%; padding:8px; margin:3px 0; background:#fafafa; border:1px solid #dbdbdb;"><br>
    <button style="background:#0095f6; color:white; width:100%; padding:7px; border:none; border-radius:4px;">Log In</button>
  </div>
</div>''',
    };

    return templates[targetSite.toLowerCase()] ?? templates['google']!;
  }

  /// توليد رسالة تصيد (Phishing Email)
  static String generatePhishingEmail({
    required String targetName,
    required String fromName,
    required String fromCompany,
    String subject = 'Urgent: Account Verification Required',
  }) {
    final templates = [
      '''
Subject: $subject
From: $fromName <security@${fromCompany.toLowerCase().replaceAll(' ', '')}.com>
To: $targetName

Dear $targetName,

We have detected unusual activity on your ${fromCompany} account. 
Your account has been temporarily suspended for security reasons.

To reactivate your account, please verify your identity by clicking the link below:
[VERIFY ACCOUNT]

This link will expire in 24 hours.

Best regards,
${fromCompany} Security Team
''',
      '''
Subject: Your Password Expires Today
From: $fromName <admin@${fromCompany.toLowerCase().replaceAll(' ', '')}.org>
To: $targetName

Hello $targetName,

Your $fromCompany password expires today. 
Please update it immediately to avoid losing access to your account.

Update Password: [CLICK HERE]

Thank you,
$fromName
${fromCompany} IT Department
''',
    ];

    return templates[Random().nextInt(templates.length)];
  }

  /// توليد رابط تصيد (Phishing URL)
  static String generatePhishingUrl(String realDomain) {
    final tricks = [
      realDomain.replaceAll('o', '0'),
      realDomain.replaceAll('l', '1'),
      realDomain.replaceAll('e', '3'),
      '$realDomain-login.com',
      '$realDomain-verify.com',
      '$realDomain-secure.com',
      '$realDomain.account.com',
      'www.$realDomain.com.verify.info',
      'login-$realDomain.com',
    ];
    return tricks[Random().nextInt(tricks.length)];
  }

  /// تحليل هدف لجمع معلومات عنه
  static Map<String, String> analyzeTarget({
    String? name,
    String? email,
    String? phone,
  }) {
    final profile = <String, String>{};
    
    if (name != null) {
      profile['full_name'] = name;
      profile['first_name'] = name.split(' ').first;
      profile['last_name'] = name.split(' ').length > 1 ? name.split(' ').last : '';
    }
    if (email != null) {
      profile['email'] = email;
      profile['email_provider'] = email.split('@').length > 1 ? email.split('@')[1] : 'Unknown';
    }
    if (phone != null) {
      profile['phone'] = phone;
      profile['phone_type'] = phone.startsWith('+') ? 'International' : 'Local';
    }
    
    // توليد أسئلة أمان محتملة
    profile['security_question_hints'] = 'Pet name, Mother maiden name, Birth city, First school';
    
    return profile;
  }

  /// توليد قائمة كلمات مرور مخصصة للهدف
  static List<String> generateTargetedWordlist(Map<String, String> profile) {
    final wordlist = <String>{};
    
    final keywords = <String>[];
    if (profile.containsKey('first_name')) keywords.add(profile['first_name']!);
    if (profile.containsKey('last_name')) keywords.add(profile['last_name']!);
    if (profile.containsKey('email')) {
      final emailName = profile['email']!.split('@')[0];
      keywords.add(emailName);
    }
    
    for (final word in keywords) {
      wordlist.add(word);
      wordlist.add('${word}123');
      wordlist.add('${word}2024');
      wordlist.add('${word}2025');
      wordlist.add('${word}!');
      wordlist.add('${word}@');
    }
    
    return wordlist.toList();
  }
}
