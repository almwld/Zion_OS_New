import 'dart:convert';

class OutputTruncator {
  static const int maxBytes=100*1024;
  const OutputTruncator();
  String truncate(String output) {
    final bytes=utf8.encode(output);
    if(bytes.length<=maxBytes)return output;
    final preview=utf8.decode(bytes.take(maxBytes).toList(),allowMalformed:true);
    return '$preview\n...[اقتُطع: ${output.length-preview.length} محرفاً]';
  }
}
