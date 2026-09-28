import 'dart:async';
import 'dart:io';

class NetworkProbeResult {
  const NetworkProbeResult({required this.host, required this.port, required this.open, required this.latencyMs});
  final String host;
  final int port;
  final bool open;
  final int latencyMs;
}

class RealNetworkEngine {
  static final RegExp _ipv4 = RegExp(r'^(?:\d{1,3}\.){3}\d{1,3}\$');

  static bool isSafeHost(String host) {
    if (host.length > 253 || host.contains(RegExp(r'[\s/\\]'))) return false;
    if (_ipv4.hasMatch(host)) {
      final octets = host.split('.').map(int.parse).toList();
      return octets.every((n) => n >= 0 && n <= 255);
    }
    return RegExp(r'^[A-Za-z0-9][A-Za-z0-9.-]*\$').hasMatch(host);
  }

  Future<NetworkProbeResult> probeTcp(String host, int port, {Duration timeout = const Duration(seconds: 2)}) async {
    if (!isSafeHost(host) || port < 1 || port > 65535) {
      throw ArgumentError('Invalid host or port');
    }
    final started = DateTime.now();
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();
      return NetworkProbeResult(host: host, port: port, open: true, latencyMs: DateTime.now().difference(started).inMilliseconds);
    } on SocketException {
      return NetworkProbeResult(host: host, port: port, open: false, latencyMs: DateTime.now().difference(started).inMilliseconds);
    }
  }

  Future<List<NetworkProbeResult>> scanPorts(String host, Iterable<int> ports, {int concurrency = 16}) async {
    if (!isSafeHost(host)) throw ArgumentError('Invalid host');
    final results = <NetworkProbeResult>[];
    final queue = ports.where((p) => p >= 1 && p <= 65535).toList();
    for (var i = 0; i < queue.length; i += concurrency) {
      final batch = queue.skip(i).take(concurrency);
      results.addAll(await Future.wait(batch.map((p) => probeTcp(host, p))));
    }
    return results;
  }

  Future<List<String>> pingSweep(String subnetPrefix, {int start = 1, int end = 254}) async {
    if (!RegExp(r'^(?:\d{1,3}\.){3}\$').hasMatch(subnetPrefix)) throw ArgumentError('Use an IPv4 prefix such as 192.168.1.');
    final hosts = <String>[];
    for (var i = start.clamp(1, 254); i <= end.clamp(1, 254); i++) {
      final host = '$subnetPrefix$i';
      final result = await probeTcp(host, 80, timeout: const Duration(milliseconds: 700));
      if (result.open) hosts.add(host);
    }
    return hosts;
  }
}
