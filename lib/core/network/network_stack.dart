import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class DnsResolver {
  Future<List<String>> resolve(String host) async {
    final addresses = await InternetAddress.lookup(host);
    return addresses.map((a) => a.address).toList();
  }
}

class HttpClientService {
  Future<String> get(Uri uri, {Map<String, String>? headers}) async {
    if (uri.scheme != 'https' && uri.scheme != 'http') throw ArgumentError('Only HTTP(S) is supported');
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers?.forEach(request.headers.add);
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) throw HttpException('HTTP ${response.statusCode}', uri: uri);
      return body;
    } finally { client.close(force: true); }
  }
}

class ProxyManager {
  String? _host;
  int? _port;
  void configure({required String host, required int port}) {
    if (host.isEmpty || port < 1 || port > 65535) throw ArgumentError('Invalid proxy');
    _host = host; _port = port;
  }
  void clear() { _host = null; _port = null; }
  bool get configured => _host != null && _port != null;
  String? get address => configured ? '$_host:$_port' : null;
  HttpClient apply(HttpClient client) {
    if (configured) client.findProxy = (_) => 'PROXY $_host:$_port';
    return client;
  }
}

class PacketInspector {
  Map<String, dynamic> inspect(Uint8List bytes) {
    if (bytes.length < 1) return {'status': 'UNAVAILABLE', 'reason': 'empty packet'};
    final version = (bytes[0] >> 4) & 0xf;
    if (version == 4 && bytes.length >= 20) {
      final ihl = (bytes[0] & 0xf) * 4;
      final protocol = bytes[9];
      return {'status': 'REAL', 'ipVersion': 4, 'headerLength': ihl, 'protocol': _protocol(protocol), 'totalLength': (bytes[2] << 8) | bytes[3]};
    }
    if (version == 6 && bytes.length >= 40) return {'status': 'REAL', 'ipVersion': 6, 'nextHeader': _protocol(bytes[6]), 'payloadLength': (bytes[4] << 8) | bytes[5]};
    return {'status': 'UNAVAILABLE', 'reason': 'unsupported or truncated IP packet'};
  }
  String _protocol(int value) => switch (value) { 6 => 'TCP', 17 => 'UDP', 1 => 'ICMP', 58 => 'ICMPv6', _ => 'IP/$value' };
}

class LivePacketCapture {
  Stream<Uint8List> capture() => const Stream<Uint8List>.empty();
  String get status => 'UNAVAILABLE: raw packet capture requires platform VPN/root/native capture integration';
}
