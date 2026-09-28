import 'dart:io';
import 'dart:async';

class NetworkEngine {
  static Future<List<String>> pingSweep(String subnet) async {
    final activeHosts = <String>[];
    final futures = <Future>[];
    
    for (var i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      futures.add(
        Process.run('ping', ['-c', '1', '-W', '1', ip])
          .then((result) {
            if (result.exitCode == 0) activeHosts.add(ip);
          }).catchError((_) {})
      );
    }
    await Future.wait(futures);
    activeHosts.sort();
    return activeHosts;
  }
  
  static Future<List<int>> scanPorts(String host, List<int> ports) async {
    final openPorts = <int>[];
    for (final port in ports) {
      try {
        final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 1));
        socket.destroy();
        openPorts.add(port);
        print("✅ Port $port open on $host");
      } catch (_) {
        print("❌ Port $port closed on $host");
      }
    }
    openPorts.sort();
    return openPorts;
  }
  
  static Future<Map<int, String>> scanWithBanner(String host, List<int> ports) async {
    final results = <int, String>{};
    for (final port in ports) {
      try {
        final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
        final completer = Completer<String>();
        socket.listen((data) {
          completer.complete(String.fromCharCodes(data).trim());
          socket.destroy();
        });
        final banner = await completer.future.timeout(const Duration(seconds: 2), onTimeout: () => 'No banner');
        if (banner.isNotEmpty && banner != 'No banner') {
          results[port] = banner;
        }
      } catch (_) {}
    }
    return results;
  }
}
