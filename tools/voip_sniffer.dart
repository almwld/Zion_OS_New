import 'dart:async';
import 'dart:io';

class VoipSniffer {
  final List<Map<String, dynamic>> _capturedCalls = [];
  bool _isListening = false;
  StreamSubscription? _subscription;

  /// بدء التنصت على مكالمات VoIP
  Future<void> startListening() async {
    _isListening = true;
    
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5060);
      
      _subscription = socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            _processPacket(datagram.data);
          }
        }
      });
    } catch (_) {}
  }

  /// معالجة حزمة VoIP
  void _processPacket(List<int> data) {
    final content = String.fromCharCodes(data);
    
    // تحليل SIP
    if (content.contains('SIP')) {
      final call = _parseSipPacket(content);
      if (call != null) {
        _capturedCalls.add(call);
      }
    }
    
    // تحليل RTP
    if (content.contains('RTP')) {
      _capturedCalls.add({
        'protocol': 'RTP',
        'size': data.length,
        'time': DateTime.now().toIso8601String(),
      });
    }
  }

  /// تحليل حزمة SIP
  Map<String, dynamic>? _parseSipPacket(String content) {
    final call = <String, dynamic>{
      'protocol': 'SIP',
      'time': DateTime.now().toIso8601String(),
    };

    final fromMatch = RegExp(r'From:\s*.*?sip:([^@]+)@', caseSensitive: false).firstMatch(content);
    final toMatch = RegExp(r'To:\s*.*?sip:([^@]+)@', caseSensitive: false).firstMatch(content);
    final methodMatch = RegExp(r'^(INVITE|BYE|ACK|CANCEL|REGISTER)', caseSensitive: false).firstMatch(content);
    final callIdMatch = RegExp(r'Call-ID:\s*(.+)', caseSensitive: false).firstMatch(content);

    if (fromMatch != null) call['from'] = fromMatch.group(1);
    if (toMatch != null) call['to'] = toMatch.group(1);
    if (methodMatch != null) call['method'] = methodMatch.group(1);
    if (callIdMatch != null) call['call_id'] = callIdMatch.group(1);

    return call.isNotEmpty ? call : null;
  }

  /// الحصول على المكالمات الملتقطة
  List<Map<String, dynamic>> getCapturedCalls() => _capturedCalls;

  /// إيقاف التنصت
  Future<void> stopListening() async {
    _isListening = false;
    await _subscription?.cancel();
  }
}
