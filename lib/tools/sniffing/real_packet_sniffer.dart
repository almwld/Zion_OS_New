import 'dart:async';
import 'dart:io';
import 'dart:convert';

class RealPacketSniffer {
  final List<Map<String, dynamic>> capturedPackets = [];
  ServerSocket? _server;
  bool _isRunning = false;

  /// بدء الالتقاط على منفذ
  Future<bool> startCapture({int port = 8080}) async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;

      _server!.listen((socket) {
        final remoteIp = socket.remoteAddress.address;
        final remotePort = socket.remotePort;

        socket.listen((data) {
          capturedPackets.add({
            'timestamp': DateTime.now().toIso8601String(),
            'source': {'ip': remoteIp, 'port': remotePort},
            'destination': {'ip': '0.0.0.0', 'port': port},
            'size': data.length,
            'data': _safeDecode(data),
            'hex': data.take(50).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
          });

          if (capturedPackets.length > 5000) capturedPackets.removeAt(0);
        });
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// إيقاف الالتقاط
  void stopCapture() {
    _isRunning = false;
    _server?.close();
    _server = null;
  }

  /// الحصول على الحزم الملتقطة
  List<Map<String, dynamic>> getPackets({int? limit}) {
    if (limit != null && capturedPackets.length > limit) {
      return capturedPackets.sublist(capturedPackets.length - limit);
    }
    return capturedPackets;
  }

  /// مسح الحزم
  void clearPackets() => capturedPackets.clear();

  /// تحليل بروتوكول HTTP
  static Map<String, dynamic>? parseHttp(String raw) {
    try {
      final lines = raw.split('\r\n');
      if (lines.isEmpty || !lines[0].contains('HTTP')) return null;

      final requestLine = lines[0].split(' ');
      final headers = <String, String>{};
      int i = 1;
      while (i < lines.length && lines[i].isNotEmpty) {
        final parts = lines[i].split(': ');
        if (parts.length >= 2) headers[parts[0]] = parts.sublist(1).join(': ');
        i++;
      }

      return {
        'method': requestLine[0],
        'path': requestLine[1],
        'version': requestLine[2],
        'headers': headers,
        'host': headers['Host'] ?? 'unknown',
        'user_agent': headers['User-Agent'] ?? 'unknown',
      };
    } catch (_) {
      return null;
    }
  }

  String _safeDecode(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(bytes.take(200));
    }
  }
}
