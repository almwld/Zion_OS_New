import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';

import '../userland/zion_bootstrap.dart';
import '../userland/zion_proot.dart';

class LlmIntegration {
  Uri? _endpoint;
  String? _token;
  void configure({required Uri endpoint, String? bearerToken}) {
    if (endpoint.scheme != 'https' && endpoint.scheme != 'http') throw ArgumentError('LLM endpoint must use HTTP(S)');
    _endpoint = endpoint; _token = bearerToken;
  }

  Future<Map<String, dynamic>> complete({required String prompt, Map<String, dynamic>? extra}) async {
    final endpoint = _endpoint;
    if (endpoint == null) return {'status': 'UNAVAILABLE', 'reason': 'LLM endpoint is not configured'};
    final client = HttpClient();
    try {
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      if (_token != null && _token!.isNotEmpty) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_token');
      request.write(jsonEncode({'prompt': prompt, ...?extra}));
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) return {'status': 'FAILED', 'httpStatus': response.statusCode, 'body': body};
      dynamic decoded;
      try { decoded = jsonDecode(body); } catch (_) { decoded = body; }
      return {'status': 'REAL', 'data': decoded};
    } finally { client.close(force: true); }
  }
}

class WebSocketIntegration {
  IOWebSocketChannel? _channel;
  final StreamController<String> _messages = StreamController.broadcast();
  Stream<String> get messages => _messages.stream;
  bool get connected => _channel != null;

  Future<void> connect(Uri uri) async {
    if (uri.scheme != 'ws' && uri.scheme != 'wss') throw ArgumentError('WebSocket URI required');
    await close();
    _channel = IOWebSocketChannel.connect(uri);
    await _channel!.ready;
    _channel!.stream.listen((data) => _messages.add(data.toString()), onError: (Object e) => _messages.addError(e), onDone: () => _channel = null);
  }
  void send(dynamic data) { final c = _channel; if (c == null) throw StateError('WebSocket is not connected'); c.sink.add(data is String ? data : jsonEncode(data)); }
  Future<void> close() async { final c = _channel; _channel = null; await c?.sink.close(); }
  Future<void> dispose() async { await close(); await _messages.close(); }
}

class ExternalRuntimeStatus {
  const ExternalRuntimeStatus(this.name, this.available, this.detail);
  final String name;
  final bool available;
  final String detail;
  Map<String, dynamic> toJson() => {'name': name, 'available': available, 'detail': detail};
}

class ExternalSystems {
  Future<List<ExternalRuntimeStatus>> probe() async => [
        await _probePath('Zion Userland', ZionBootstrap.prefix + '/etc/zion-release.json'),
        await _probePath('Zion Package Manager', ZionBootstrap.prefix + '/bin/zion-pkg'),
        await _probePath('Zion API', ZionBootstrap.prefix + '/bin/zion-api-battery'),
        await _probePath('Zion PRoot', ZionBootstrap.prefix + '/bin/proot'),
        await _probePath('Zion Kali rootfs', '/data/data/com.zion.os/files/home/.zion/dists/kali/rootfs/etc/os-release'),
        await _probePath('Zion Ubuntu rootfs', '/data/data/com.zion.os/files/home/.zion/dists/ubuntu/rootfs/etc/os-release'),
        await _probePath('Zion Debian rootfs', '/data/data/com.zion.os/files/home/.zion/dists/debian/rootfs/etc/os-release'),
        await _probePath('Zion Alpine rootfs', '/data/data/com.zion.os/files/home/.zion/dists/alpine/rootfs/etc/os-release'),
        await _probePath('Zion Arch rootfs', '/data/data/com.zion.os/files/home/.zion/dists/arch/rootfs/etc/os-release'),
      ];
  Future<ExternalRuntimeStatus> _probePath(String name, String path) async {
    final exists = await File(path).exists();
    return ExternalRuntimeStatus(name, exists, exists ? path : 'UNAVAILABLE: marker not found');
  }
}
