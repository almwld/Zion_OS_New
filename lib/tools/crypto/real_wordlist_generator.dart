import 'dart:math';

class RealWordlistGenerator {
  /// توليد قائمة كلمات مخصصة
  static List<String> generate({required String firstName, required String lastName, required String birthYear, String? pet, String? company}) {
    final wordlist = <String>{};
    final base = [firstName, lastName, pet, company].whereType<String>().toList();

    for (final word in base) {
      wordlist.addAll([
        word, word.toLowerCase(), word.toUpperCase(),
        '$word${birthYear}', '${birthYear}$word',
        '$word@${birthYear}', '$word#$birthYear',
        '$word!', '$word@', '$word#',
        '$word${birthYear}!',
      ]);
    }

    // كلمات شائعة
    wordlist.addAll(['password', 'admin', 'root', '12345678', 'qwerty', 'letmein', 'welcome', 'monkey', 'dragon']);

    return wordlist.toList();
  }

  /// قائمة كلمات شائعة جاهزة
  static List<String> getCommonWordlist() {
    return ['password', '123456', '12345678', 'qwerty', 'admin', 'letmein', 'welcome', 'monkey', 'dragon', 'master', 'shadow', 'football', 'baseball', 'iloveyou', 'trustno1', 'sunshine', 'princess'];
  }
}
