import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class CompletePacketAnalyzer {
  final List<Map<String, dynamic>> _packets = [];
  final List<String> _alerts = [];
  ServerSocket? _server;
  bool _isRunning = false;

  /// بدء الالتقاط
  Future<void> startCapture({int port = 8888}) async {
    _isRunning = true;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    
    _server!.listen((socket) {
      socket.listen((data) {
        _processPacket(socket.remoteAddress.address, socket.port, data);
      });
    });
  }

  /// معالجة حزمة
  void _processPacket(String srcIp, int srcPort, List<int> data) {
    if (data.length < 20) return;

    final packet = <String, dynamic>{
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'source': {'ip': srcIp, 'port': srcPort},
      'destination': {'ip': '0.0.0.0', 'port': 0},
      'protocol': 'unknown',
      'length': data.length,
      'flags': <String>[],
      'payload': '',
    };

    // تحليل IP Header
    final version = (data[0] >> 4) & 0x0F;
    final headerLength = (data[0] & 0x0F) * 4;
    final protocol = data[9];
    final srcIpBytes = data.sublist(12, 16);
    final dstIpBytes = data.sublist(16, 20);
    
    packet['source']['ip'] = srcIpBytes.join('.');
    packet['destination']['ip'] = dstIpBytes.join('.');

    // تحليل TCP
    if (protocol == 6 && data.length >= headerLength + 20) {
      final tcpStart = headerLength;
      packet['protocol'] = 'TCP';
      packet['source']['port'] = (data[tcpStart] << 8) | data[tcpStart + 1];
      packet['destination']['port'] = (data[tcpStart + 2] << 8) | data[tcpStart + 3];
      
      final flags = data[tcpStart + 13];
      if (flags & 0x01 != 0) packet['flags'].add('FIN');
      if (flags & 0x02 != 0) packet['flags'].add('SYN');
      if (flags & 0x04 != 0) packet['flags'].add('RST');
      if (flags & 0x08 != 0) packet['flags'].add('PSH');
      if (flags & 0x10 != 0) packet['flags'].add('ACK');
      if (flags & 0x20 != 0) packet['flags'].add('URG');

      final payloadStart = headerLength + ((data[tcpStart + 12] >> 4) & 0x0F) * 4;
      if (data.length > payloadStart) {
        packet['payload'] = _safeDecode(data.sublist(payloadStart));
      }
    }
    // تحليل UDP
    else if (protocol == 17 && data.length >= headerLength + 8) {
      final udpStart = headerLength;
      packet['protocol'] = 'UDP';
      packet['source']['port'] = (data[udpStart] << 8) | data[udpStart + 1];
      packet['destination']['port'] = (data[udpStart + 2] << 8) | data[udpStart + 3];
    }
    // تحليل ICMP
    else if (protocol == 1) {
      packet['protocol'] = 'ICMP';
      packet['icmp_type'] = data[headerLength];
      packet['icmp_code'] = data[headerLength + 1];
    }

    // اكتشاف الهجمات
    final alert = _detectAttack(packet);
    if (alert != null) {
      _alerts.add(alert);
      packet['alert'] = alert;
    }

    _packets.add(packet);
    if (_packets.length > 10000) _packets.removeAt(0);
  }

  /// اكتشاف هجوم
  String? _detectAttack(Map<String, dynamic> packet) {
    final flags = packet['flags'] as List<String>;
    final payload = packet['payload'] as String? ?? '';
    final srcPort = packet['source']['port'] as int;
    final dstPort = packet['destination']['port'] as int;

    // SYN Flood
    if (flags.contains('SYN') && !flags.contains('ACK')) {
      final synCount = _packets.where((p) => 
        p['source']['ip'] == packet['source']['ip'] &&
        (p['flags'] as List).contains('SYN') &&
        !(p['flags'] as List).contains('ACK')
      ).length;
      if (synCount > 100) return 'SYN Flood from ${packet['source']['ip']} ($synCount packets)';
    }

    // SQL Injection
    if (payload.contains(RegExp(r"(\bUNION\b|\bSELECT\b|' OR '1'='1)", caseSensitive: false))) {
      return 'SQL Injection attempt from ${packet['source']['ip']}';
    }

    // XSS
    if (payload.contains(RegExp(r'(<script>|<img[^>]+onerror=)', caseSensitive: false))) {
      return 'XSS attempt from ${packet['source']['ip']}';
    }

    // Port Scan
    final scanCount = _packets.where((p) => 
      p['source']['ip'] == packet['source']['ip'] &&
      (p['flags'] as List).contains('SYN')
    ).length;
    if (scanCount > 50) return 'Port Scan from ${packet['source']['ip']} ($scanCount ports)';

    return null;
  }

  /// فك تشفير آمن
  String _safeDecode(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }

  /// إيقاف الالتقاط
  void stopCapture() {
    _isRunning = false;
    _server?.close();
  }

  /// الحصول على الحزم
  List<Map<String, dynamic>> getPackets({int limit = 100}) {
    return _packets.length > limit ? _packets.sublist(_packets.length - limit) : _packets;
  }

  /// الحصول على التنبيهات
  List<String> getAlerts() => _alerts;

  /// إحصائيات
  Map<String, int> getStats() {
    final protocols = <String, int>{};
    for (final p in _packets) {
      protocols[p['protocol']] = (protocols[p['protocol']] ?? 0) + 1;
    }
    return protocols;
  }
}
