import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/features/terminal/arabic_shaper.dart';

void main() {
  group('ArabicShaper readable terminal output', () {
    test('detects Arabic text without reversing Unicode characters', () {
      const text = 'مرحبا بالعالم';
      expect(ArabicShaper.isArabic(text), isTrue);
      expect(ArabicShaper.readableText(text), text);
    });

    test('preserves mixed Arabic and shell commands', () {
      const text = 'مرحبا: ls -la';
      expect(ArabicShaper.readableText(text), text);
      expect(ArabicShaper.isArabic(text), isTrue);
    });

    test('removes ANSI formatting and normalizes line endings', () {
      const text = '\u001B[32mمرحبا\u001B[0m\r\n$ pwd\r';
      expect(ArabicShaper.readableText(text), 'مرحبا\n$ pwd\n');
    });
  });
}
