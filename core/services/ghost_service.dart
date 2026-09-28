import 'dart:math';

class GhostService {
  bool _isInvisible = false;

  /// تفعيل وضع الشبح
  void enableGhostMode() {
    _isInvisible = true;
  }

  void disableGhostMode() {
    _isInvisible = false;
  }

  /// تنظيف السجلات بعد الهجوم
  static Future<Map<String, String>> clearTraces(String target) async {
    final actions = <String, String>{};

    // محاكاة تنظيف أنواع مختلفة من السجلات
    actions['shell_history'] = _simulateClean('~/.bash_history');
    actions['system_logs'] = _simulateClean('/var/log/syslog');
    actions['auth_logs'] = _simulateClean('/var/log/auth.log');
    actions['apache_logs'] = _simulateClean('/var/log/apache2/access.log');
    actions['tmp_files'] = _simulateClean('/tmp/*');
    actions['ssh_logs'] = _simulateClean('~/.ssh/known_hosts');

    return actions;
  }

  /// تزوير السجلات
  static String spoofLog(String originalEntry, String fakeEntry) {
    return 'Log entry modified: "$originalEntry" -> "$fakeEntry"';
  }

  /// إنشاء هوية مزيفة
  static Map<String, String> generateFakeIdentity() {
    final firstNames = ['John', 'Jane', 'Alex', 'Sarah', 'Mike', 'Emily'];
    final lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Davis', 'Miller'];
    final domains = ['gmail.com', 'outlook.com', 'proton.me', 'tutanota.com'];

    final firstName = firstNames[Random().nextInt(firstNames.length)];
    final lastName = lastNames[Random().nextInt(lastNames.length)];

    return {
      'name': '$firstName $lastName',
      'email': '${firstName.toLowerCase()}.${lastName.toLowerCase()}@${domains[Random().nextInt(domains.length)]}',
      'ip': '${Random().nextInt(223) + 1}.${Random().nextInt(255)}.${Random().nextInt(255)}.${Random().nextInt(255)}',
      'user_agent': _generateUserAgent(),
      'location': _generateLocation(),
    };
  }

  /// توليد User-Agent مزيف
  static String _generateUserAgent() {
    final agents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0',
      'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/120.0',
    ];
    return agents[Random().nextInt(agents.length)];
  }

  /// توليد موقع مزيف
  static String _generateLocation() {
    final cities = ['New York, US', 'London, UK', 'Berlin, DE', 'Tokyo, JP', 'Sydney, AU'];
    return cities[Random().nextInt(cities.length)];
  }

  static String _simulateClean(String path) {
    return 'Cleaned $path (${Random().nextInt(100)} entries removed)';
  }
}
