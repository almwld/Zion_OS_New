import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class ProtocolEngineer {
  /// بناء حزمة TCP مخصصة
  static Uint8List craftTcpPacket({
    required String srcIp,
    required String dstIp,
    required int srcPort,
    required int dstPort,
    int seq = 0,
    int ack = 0,
    int flags = 0x02, // SYN
    String payload = '',
  }) {
    final buffer = BytesBuilder();

    // IP Header (20 bytes)
    buffer.addByte(0x45); // Version + IHL
    buffer.addByte(0x00); // DSCP + ECN
    buffer.add([0x00, 0x28]); // Total Length (placeholder)
    buffer.add([0x00, 0x01]); // Identification
    buffer.add([0x40, 0x00]); // Flags + Fragment
    buffer.addByte(0x40); // TTL
    buffer.addByte(0x06); // Protocol (TCP)
    buffer.add([0x00, 0x00]); // Header Checksum (placeholder)
    buffer.add(_ipToBytes(srcIp));
    buffer.add(_ipToBytes(dstIp));

    // TCP Header (20 bytes)
    buffer.add([(srcPort >> 8) & 0xFF, srcPort & 0xFF]);
    buffer.add([(dstPort >> 8) & 0xFF, dstPort & 0xFF]);
    buffer.add(_intTo4Bytes(seq));
    buffer.add(_intTo4Bytes(ack));
    buffer.addByte(0x50); // Data Offset
    buffer.addByte(flags);
    buffer.add([0xFF, 0xFF]); // Window Size
    buffer.add([0x00, 0x00]); // Checksum (placeholder)
    buffer.add([0x00, 0x00]); // Urgent Pointer

    // Payload
    if (payload.isNotEmpty) {
      buffer.add(utf8.encode(payload));
    }

    return buffer.toBytes();
  }

  /// بناء حزمة UDP مخصصة
  static Uint8List craftUdpPacket({
    required String srcIp,
    required String dstIp,
    required int srcPort,
    required int dstPort,
    String payload = '',
  }) {
    final buffer = BytesBuilder();

    // IP Header
    buffer.addByte(0x45);
    buffer.addByte(0x00);
    buffer.add([0x00, 0x1C]);
    buffer.add([0x00, 0x01]);
    buffer.add([0x00, 0x00]);
    buffer.addByte(0x40);
    buffer.addByte(0x11); // Protocol (UDP)
    buffer.add([0x00, 0x00]);
    buffer.add(_ipToBytes(srcIp));
    buffer.add(_ipToBytes(dstIp));

    // UDP Header (8 bytes)
    buffer.add([(srcPort >> 8) & 0xFF, srcPort & 0xFF]);
    buffer.add([(dstPort >> 8) & 0xFF, dstPort & 0xFF]);
    buffer.add([0x00, 0x08]); // Length (placeholder)
    buffer.add([0x00, 0x00]); // Checksum

    if (payload.isNotEmpty) {
      buffer.add(utf8.encode(payload));
    }

    return buffer.toBytes();
  }

  /// بناء طلب HTTP مخصص
  static String craftHttpRequest({
    String method = 'GET',
    String path = '/',
    String host = 'localhost',
    Map<String, String>? headers,
    String? body,
  }) {
    final request = StringBuffer();
    request.writeln('$method $path HTTP/1.1');
    request.writeln('Host: $host');
    request.writeln('User-Agent: Mozilla/5.0 (Custom)');
    request.writeln('Accept: */*');
    request.writeln('Connection: close');

    if (headers != null) {
      for (final entry in headers.entries) {
        request.writeln('${entry.key}: ${entry.value}');
      }
    }

    if (body != null) {
      request.writeln('Content-Length: ${body.length}');
      request.writeln('');
      request.write(body);
    } else {
      request.writeln('');
    }

    return request.toString();
  }

  /// إرسال حزمة خام
  static Future<Map<String, dynamic>> sendRawPacket(Uint8List packet, String target, int port) async {
    try {
      final socket = await Socket.connect(target, port, timeout: const Duration(seconds: 3));
      socket.add(packet);
      await socket.flush();

      // قراءة الرد
      final response = <int>[];
      socket.listen((data) => response.addAll(data));
      await Future.delayed(const Duration(milliseconds: 500));
      socket.destroy();

      return {
        'sent': packet.length,
        'received': response.length,
        'response': response.isNotEmpty ? String.fromCharCodes(response).substring(0, 200) : 'No response',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// تحليل بروتوكول من بيانات خام
  static Map<String, dynamic> analyzeProtocol(List<int> data) {
    if (data.length < 20) return {'error': 'Data too short'};

    final protocol = data[9];
    final srcIp = data.sublist(12, 16).join('.');
    final dstIp = data.sublist(16, 20).join('.');

    switch (protocol) {
      case 6: return {'protocol': 'TCP', 'src': srcIp, 'dst': dstIp};
      case 17: return {'protocol': 'UDP', 'src': srcIp, 'dst': dstIp};
      case 1: return {'protocol': 'ICMP', 'src': srcIp, 'dst': dstIp};
      default: return {'protocol': 'Unknown ($protocol)', 'src': srcIp, 'dst': dstIp};
    }
  }

  static List<int> _ipToBytes(String ip) => ip.split('.').map(int.parse).toList();
  static List<int> _intTo4Bytes(int value) => [(value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF];
}
