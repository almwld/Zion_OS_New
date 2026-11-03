class OutputTruncator {
  static const int maxBytes = 100 * 1024;
  const OutputTruncator();
  String truncate(String output) {
    final bytes = output.codeUnits;
    if (bytes.length <= maxBytes) return output;
    var end = maxBytes;
    if (end > 0 && end < output.length && output.codeUnitAt(end - 1) >= 0xD800 && output.codeUnitAt(end - 1) <= 0xDBFF) end--;
    return '${output.substring(0, end)}\n...[اقتُطع: ${output.length - end} محرفاً]';
  }
}
