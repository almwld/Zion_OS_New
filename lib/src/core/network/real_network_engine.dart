import 'dart:async';
import 'dart:io';
import 'dart:math';

class RealNetworkEngine {
  /// مسح شبكة كامل (Ping Sweep) - حقيقي 100%
  static Future<List<String>> pingSweep(String subnet, {int timeout = 500}) async {
    final activeHosts = <String>[];
    final List<Future> futures = [];

    for (int i = 1; i <= 254; i++) {
      final host = '$subnet.$i';
      futures.add(
        Process.run('ping', ['-c', '1', '-W', '${timeout ~/ 1000}', host])
            .then((result) {
          if (result.exitCode == 0) {
            activeHosts.add(host);
          }
        }).catchError((_) {}),
      );
    }
    await Future.wait(futures);
    return activeHosts..sort();
  }

  /// مسح منافذ TCP حقيقي
  static Future<List<int>> scanTcpPorts(String host, {List<int>? ports, int timeout = 200}) async {
    final openPorts = <int>[];
    final targetPorts = ports ?? [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 1433, 3306, 3389, 5432, 5900, 6379, 8080, 8443, 27017];
    final List<Future> futures = [];

    for (final port in targetPorts) {
      futures.add(
        Socket.connect(host, port, timeout: Duration(milliseconds: timeout))
            .then((socket) {
          openPorts.add(port);
          socket.destroy();
        }).catchError((_) {}),
      );
    }
    await Future.wait(futures);
    openPorts.sort();
    return openPorts;
  }

  /// جلب بانر الخدمة (Banner Grabbing) حقيقي
  static Future<String?> grabBanner(String host, int port, {int timeout = 2000}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: Duration(milliseconds: timeout));
      final completer = Completer<String?>();
      final buffer = StringBuffer();

      socket.listen((data) {
        buffer.write(String.fromCharCodes(data));
        if (buffer.toString().contains('\n')) {
          completer.complete(buffer.toString().trim());
        }
      }, onDone: () {
        if (!completer.isCompleted) completer.complete(buffer.toString().trim());
      }, onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      });

      final result = await completer.future.timeout(Duration(milliseconds: timeout), onTimeout: () => buffer.toString().trim());
      socket.destroy();
      return (result != null && result.isNotEmpty) ? result : null;
    } catch (_) {
      return null;
    }
  }
}
