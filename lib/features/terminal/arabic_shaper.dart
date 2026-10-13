/// Helpers for reading plain text emitted by the terminal in Flutter widgets.
///
/// xterm2 renders a character-cell grid and does not expose a per-line
/// TextDirection hook. Keep raw PTY bytes untouched for the emulator; this
/// helper is for a separate, readable text view only.
class ArabicShaper {
  const ArabicShaper._();

  static final RegExp _ansi = RegExp(
    r'\x1B(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1B\\))',
  );
  static final RegExp _arabic =
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
  static final RegExp _unsupportedControls =
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');

  static bool isArabic(String text) => _arabic.hasMatch(text);

  static const Map<int, List<int>> _forms = <int, List<int>>{
    0x0622: [0xFE81, 0xFE82], 0x0623: [0xFE83, 0xFE84],
    0x0624: [0xFE85, 0xFE86], 0x0625: [0xFE87, 0xFE88],
    0x0626: [0xFE89, 0xFE8A, 0xFE8B, 0xFE8C], 0x0627: [0xFE8D, 0xFE8E],
    0x0628: [0xFE8F, 0xFE90, 0xFE91, 0xFE92], 0x0629: [0xFE93, 0xFE94],
    0x062A: [0xFE95, 0xFE96, 0xFE97, 0xFE98], 0x062B: [0xFE99, 0xFE9A, 0xFE9B, 0xFE9C],
    0x062C: [0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0], 0x062D: [0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4],
    0x062E: [0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8], 0x062F: [0xFEA9, 0xFEAA],
    0x0630: [0xFEAB, 0xFEAC], 0x0631: [0xFEAD, 0xFEAE],
    0x0632: [0xFEAF, 0xFEB0], 0x0633: [0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4],
    0x0634: [0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8], 0x0635: [0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC],
    0x0636: [0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0], 0x0637: [0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4],
    0x0638: [0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8], 0x0639: [0xFEC9, 0xFECA, 0xFECB, 0xFECC],
    0x063A: [0xFECD, 0xFECE, 0xFECF, 0xFED0], 0x0641: [0xFED1, 0xFED2, 0xFED3, 0xFED4],
    0x0642: [0xFED5, 0xFED6, 0xFED7, 0xFED8], 0x0643: [0xFED9, 0xFEDA, 0xFEDB, 0xFEDC],
    0x0644: [0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0], 0x0645: [0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4],
    0x0646: [0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8], 0x0647: [0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC],
    0x0648: [0xFEED, 0xFEEE], 0x0649: [0xFEEF, 0xFEF0],
    0x064A: [0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4],
    0x067E: [0xFB56, 0xFB57, 0xFB58, 0xFB59],
    0x0686: [0xFB7A, 0xFB7B, 0xFB7C, 0xFB7D],
    0x0698: [0xFB8A, 0xFB8B],
    0x06AF: [0xFB92, 0xFB93, 0xFB94, 0xFB95],
  };

  static bool _joinsPrevious(int cp) => _forms[cp] != null;
  static bool _joinsNext(int cp) => (_forms[cp]?.length ?? 0) == 4;

  /// Shapes ordinary text previews only; live PTY ANSI data stays untouched.
  static String shape(String text) {
    final runes = text.runes.toList(growable: false);
    final out = StringBuffer();
    for (var i = 0; i < runes.length; i++) {
      final cp = runes[i];
      final forms = _forms[cp];
      if (forms == null) {
        out.writeCharCode(cp);
        continue;
      }
      final previous = i > 0 ? runes[i - 1] : -1;
      final next = i + 1 < runes.length ? runes[i + 1] : -1;
      final joinsPrevious = _joinsNext(previous) && _joinsPrevious(cp);
      final joinsNext = _joinsNext(cp) && _joinsPrevious(next);
      final index = joinsPrevious && joinsNext ? 3 : joinsPrevious ? 1 : joinsNext ? 2 : 0;
      out.writeCharCode(forms[index]);
    }
    return out.toString();
  }

  /// Removes terminal escape/control sequences for human-readable preview.
  /// This is deliberately not used on the live PTY stream.
  static String readableText(String text) {
    return text
        .replaceAll(_ansi, '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_unsupportedControls, '');
  }
}
