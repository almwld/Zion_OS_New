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
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
  static final RegExp _unsupportedControls =
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');

  static bool isArabic(String text) => _arabic.hasMatch(text);

  /// Removes terminal escape/control sequences for human-readable preview.
  /// This is deliberately not used on the live PTY stream.
  static String readableText(String text) {
    // Strip terminal styling/control bytes from a *copy* of PTY output. Never
    // feed this transformed string back to xterm2: escape sequences and cursor
    // updates are part of the live terminal protocol.
    final cleaned = text
        .replaceAll(_ansi, '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_unsupportedControls, '');
    // Remove backspace artifacts commonly emitted by line editors/progress
    // displays, without changing normal Unicode code points or Arabic order.
    final result = <int>[];
    for (final rune in cleaned.runes) {
      if (rune == 0x08) {
        if (result.isNotEmpty) result.removeLast();
      } else {
        result.add(rune);
      }
    }
    return String.fromCharCodes(result);
  }

  /// Flutter's text engine already performs Arabic shaping and Unicode bidi.
  /// Keep logical code-point order intact and set TextDirection.rtl in widgets;
  /// manually reversing Arabic here would double-reverse correct UTF-8 output.
  static String forRtlDisplay(String text) => readableText(text);
}
