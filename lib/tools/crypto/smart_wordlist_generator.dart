import 'dart:math';

class SmartWordlistGenerator {
  /// توليد قائمة كلمات مرور مخصصة بناءً على معلومات الهدف
  static List<String> generate({
    String? name,
    String? birthdate,
    String? pet,
    String? hobby,
    String? company,
    int maxLength = 12,
  }) {
    final wordlist = <String>{};
    
    // الكلمات الأساسية
    final baseWords = <String>[];
    if (name != null) {
      baseWords.addAll(name.split(' '));
      baseWords.add(name.replaceAll(' ', ''));
      baseWords.add(name.replaceAll(' ', '').toLowerCase());
    }
    if (pet != null) baseWords.add(pet);
    if (hobby != null) baseWords.add(hobby);
    if (company != null) {
      baseWords.add(company);
      baseWords.add(company.replaceAll(' ', ''));
    }
    
    // توليد التركيبات
    for (final word in baseWords) {
      wordlist.add(word);
      wordlist.add(word.toLowerCase());
      wordlist.add(word.toUpperCase());
      wordlist.add('${word}123');
      wordlist.add('${word}1234');
      wordlist.add('${word}12345');
      wordlist.add('${word}123456');
      wordlist.add('${word}@123');
      wordlist.add('${word}!');
      wordlist.add('${word}@');
      wordlist.add('${word}#');
      wordlist.add('${word}2024');
      wordlist.add('${word}2025');
      wordlist.add('${word}2026');
      wordlist.add('123${word}');
      wordlist.add('password${word}');
      wordlist.add('${word}password');
      
      // قلب الكلمة
      wordlist.add(word.split('').reversed.join());
      
      // تكرار
      wordlist.add('$word$word');
      
      // استبدال الحروف بأرقام
      wordlist.add(word
        .replaceAll('a', '@')
        .replaceAll('e', '3')
        .replaceAll('i', '1')
        .replaceAll('o', '0')
        .replaceAll('s', '\$'));
    }
    
    // إضافة تواريخ
    if (birthdate != null) {
      final dates = _generateDateVariations(birthdate);
      wordlist.addAll(dates);
      for (final word in baseWords) {
        for (final date in dates) {
          wordlist.add('$word$date');
          wordlist.add('$date$word');
        }
      }
    }
    
    // قائمة كلمات شائعة إضافية
    wordlist.addAll([
      'admin', 'Admin', 'ADMIN',
      'password', 'Password', 'PASSWORD',
      '123456', '12345678', '123456789',
      'qwerty', 'Qwerty', 'QWERTY',
      'letmein', 'welcome', 'monkey',
      'dragon', 'master', 'shadow',
      'sunshine', 'princess', 'football',
    ]);
    
    // تصفية حسب الطول
    return wordlist.where((w) => w.length >= 6 && w.length <= maxLength).toList();
  }

  /// توليد كلمات مرور عشوائية قوية
  static String generateStrongPassword({int length = 16}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final random = Random();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// توليد كلمات مرور بنمط معين
  static List<String> generatePattern(String pattern, {int count = 10}) {
    final wordlist = <String>[];
    final random = Random();
    
    for (int i = 0; i < count; i++) {
      String password = '';
      for (final char in pattern.split('')) {
        switch (char) {
          case 'L': password += String.fromCharCode(random.nextInt(26) + 65); break; // حرف كبير
          case 'l': password += String.fromCharCode(random.nextInt(26) + 97); break; // حرف صغير
          case 'D': password += random.nextInt(10).toString(); break; // رقم
          case 'S': password += '!@#\$%^&*'[random.nextInt(8)]; break; // رمز
        }
      }
      wordlist.add(password);
    }
    
    return wordlist;
  }

  static List<String> _generateDateVariations(String date) {
    final variations = <String>[];
    final parts = date.split(RegExp(r'[/\\-]'));
    
    if (parts.length >= 2) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts.length >= 3 ? parts[2] : '';
      final shortYear = year.length == 4 ? year.substring(2) : year;
      
      variations.add('$day$month');
      variations.add('$month$day');
      variations.add('$day$month$year');
      variations.add('$day$month$shortYear');
      variations.add('$month$day$year');
      variations.add('$month$day$shortYear');
    }
    
    return variations;
  }
}
