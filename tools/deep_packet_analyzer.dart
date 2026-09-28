class DeepPacketAnalyzer {
  /// تحليل حزمة TCP
  static Map<String, dynamic> analyzeTcpPacket(List<int> data) {
    if (data.length < 20) return {'error': 'Packet too short'};
    
    final srcPort = (data[0] << 8) | data[1];
    final dstPort = (data[2] << 8) | data[3];
    final flags = data[13];
    
    return {
      'protocol': 'TCP',
      'src_port': srcPort,
      'dst_port': dstPort,
      'flags': _parseTcpFlags(flags),
      'service': _guessService(dstPort),
      'length': data.length,
    };
  }

  /// تحليل حزمة UDP
  static Map<String, dynamic> analyzeUdpPacket(List<int> data) {
    if (data.length < 8) return {'error': 'Packet too short'};
    
    final srcPort = (data[0] << 8) | data[1];
    final dstPort = (data[2] << 8) | data[3];
    
    return {
      'protocol': 'UDP',
      'src_port': srcPort,
      'dst_port': dstPort,
      'service': _guessService(dstPort),
      'length': data.length,
    };
  }

  /// تحليل حزمة ICMP
  static Map<String, dynamic> analyzeIcmpPacket(List<int> data) {
    if (data.length < 8) return {'error': 'Packet too short'};
    
    final type = data[0];
    final code = data[1];
    
    return {
      'protocol': 'ICMP',
      'type': _icmpType(type),
      'code': code,
      'length': data.length,
    };
  }

  /// تحليل طلب HTTP
  static Map<String, dynamic>? analyzeHttpRequest(String data) {
    final lines = data.split('\r\n');
    if (lines.isEmpty) return null;
    
    final requestLine = lines[0].split(' ');
    if (requestLine.length < 3) return null;
    
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      if (line.isEmpty) break;
      final parts = line.split(': ');
      if (parts.length == 2) {
        headers[parts[0]] = parts[1];
      }
    }
    
    return {
      'protocol': 'HTTP',
      'method': requestLine[0],
      'path': requestLine[1],
      'version': requestLine[2],
      'headers': headers,
      'user_agent': headers['User-Agent'] ?? 'Unknown',
      'host': headers['Host'] ?? 'Unknown',
    };
  }

  /// اكتشاف هجوم محتمل
  static String? detectAttack(Map<String, dynamic> packet) {
    // فحص SQL Injection
    if (packet['path'] != null && packet['path'].toString().contains(RegExp(r"(\bUNION\b|\bSELECT\b|' OR '1'='1)", caseSensitive: false))) {
      return 'Possible SQL Injection attack from ${packet['src']}';
    }
    
    // فحص XSS
    if (packet['path'] != null && packet['path'].toString().contains(RegExp(r'(<script>|<img[^>]+onerror=)', caseSensitive: false))) {
      return 'Possible XSS attack from ${packet['src']}';
    }
    
    // فحص Port Scan
    if (packet['protocol'] == 'TCP' && packet['flags'] != null && packet['flags'].toString().contains('SYN')) {
      return 'Possible Port Scan (SYN packet to port ${packet['dst_port']})';
    }
    
    return null;
  }

  static List<String> _parseTcpFlags(int flags) {
    final result = <String>[];
    if (flags & 0x01 != 0) result.add('FIN');
    if (flags & 0x02 != 0) result.add('SYN');
    if (flags & 0x04 != 0) result.add('RST');
    if (flags & 0x08 != 0) result.add('PSH');
    if (flags & 0x10 != 0) result.add('ACK');
    if (flags & 0x20 != 0) result.add('URG');
    return result;
  }

  static String _guessService(int port) {
    switch (port) {
      case 21: return 'FTP';
      case 22: return 'SSH';
      case 23: return 'Telnet';
      case 25: return 'SMTP';
      case 53: return 'DNS';
      case 80: return 'HTTP';
      case 110: return 'POP3';
      case 143: return 'IMAP';
      case 443: return 'HTTPS';
      case 445: return 'SMB';
      case 3306: return 'MySQL';
      case 3389: return 'RDP';
      case 8080: return 'HTTP-Proxy';
      default: return 'Unknown';
    }
  }

  static String _icmpType(int type) {
    switch (type) {
      case 0: return 'Echo Reply';
      case 3: return 'Destination Unreachable';
      case 8: return 'Echo Request';
      case 11: return 'Time Exceeded';
      default: return 'Unknown ($type)';
    }
  }
}
