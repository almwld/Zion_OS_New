import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

class WormholeService {
  ServerSocket? _server;
  final List<Socket> _tunnels = [];
  final String _encryptionKey = Random().nextInt(999999).toString();

  /// فتح النفق (Server Mode)
  Future<void> openTunnel({int port = 9999}) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('Wormhole opened on port $port');

    _server!.listen((socket) {
      _tunnels.add(socket);
      print('Tunnel connected: ${socket.remoteAddress}');

      socket.listen((data) {
        final message = _decrypt(utf8.decode(data));
        _handleMessage(socket, message);
      }, onDone: () {
        _tunnels.remove(socket);
      });
    });
  }

  /// الدخول في النفق (Client Mode)
  Future<void> enterTunnel(String host, {int port = 9999}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      _tunnels.add(socket);
      print('Entered wormhole: $host');

      socket.listen((data) {
        final message = _decrypt(utf8.decode(data));
        _handleMessage(socket, message);
      });
    } catch (e) {
      print('Failed to enter wormhole: $e');
    }
  }

  /// إرسال بيانات مشفرة عبر النفق
  void sendThroughTunnel(Map<String, dynamic> data) {
    final encrypted = _encrypt(jsonEncode(data));
    for (final tunnel in _tunnels) {
      try {
        tunnel.write(encrypted);
      } catch (_) {}
    }
  }

  /// تشفير بسيط (XOR Cipher)
  String _encrypt(String data) {
    final key = _encryptionKey;
    final result = StringBuffer();
    for (int i = 0; i < data.length; i++) {
      result.writeCharCode(data.codeUnitAt(i) ^ key.codeUnitAt(i % key.length));
    }
    return result.toString();
  }

  /// فك التشفير
  String _decrypt(String data) {
    return _encrypt(data); // XOR متماثل
  }

  void _handleMessage(Socket socket, String message) {
    try {
      final data = jsonDecode(message);
      print('Received through wormhole: $data');
    } catch (_) {}
  }

  int get activeTunnels => _tunnels.length;

  void dispose() {
    _server?.close();
    for (final tunnel in _tunnels) {
      tunnel.destroy();
    }
    _tunnels.clear();
  }
}
