import 'dart:async';
import 'dart:io';
import 'dart:convert';

class BlackHoleService {
  final List<Map<String, dynamic>> _consumedData = [];
  bool _isConsuming = false;

  /// بدء ابتلاع البيانات من كل مكان
  Future<void> startConsuming() async {
    _isConsuming = true;
    
    await Future.wait([
      _consumeNetworkTraffic(),
      _consumeDeviceInfo(),
      _consumeNearbyDevices(),
      _consumeOpenPorts(),
    ]);
  }

  /// ابتلاع حركة الشبكة
  Future<void> _consumeNetworkTraffic() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        _consumedData.add({
          'type': 'interface',
          'name': interface.name,
          'addresses': interface.addresses.map((a) => a.address).toList(),
          'time': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  /// ابتلاع معلومات الجهاز
  Future<void> _consumeDeviceInfo() async {
    _consumedData.add({
      'type': 'device',
      'os': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'cores': Platform.numberOfProcessors,
      'dart': Platform.version,
      'time': DateTime.now().toIso8601String(),
    });
  }

  /// ابتلاع الأجهزة القريبة
  Future<void> _consumeNearbyDevices() async {
    try {
      final subnet = await _getSubnet();
      if (subnet != null) {
        for (int i = 1; i <= 254; i++) {
          final ip = '$subnet.$i';
          try {
            final socket = await Socket.connect(ip, 80, timeout: const Duration(milliseconds: 200));
            _consumedData.add({
              'type': 'nearby',
              'ip': ip,
              'status': 'active',
              'time': DateTime.now().toIso8601String(),
            });
            socket.destroy();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// ابتلاع المنافذ المفتوحة للجهاز نفسه
  Future<void> _consumeOpenPorts() async {
    final commonPorts = [21, 22, 23, 25, 53, 80, 443, 8080, 8443];
    for (final port in commonPorts) {
      try {
        final socket = await Socket.connect('127.0.0.1', port, timeout: const Duration(milliseconds: 300));
        _consumedData.add({
          'type': 'self_port',
          'port': port,
          'status': 'open',
          'time': DateTime.now().toIso8601String(),
        });
        socket.destroy();
      } catch (_) {}
    }
  }

  /// الحصول على البيانات المبتلعة
  List<Map<String, dynamic>> getConsumedData() => _consumedData;

  /// تحليل البيانات واقتراح أهداف
  List<String> suggestTargets() {
    final targets = <String>[];
    for (final data in _consumedData) {
      if (data['type'] == 'nearby' && data['status'] == 'active') {
        targets.add(data['ip'].toString());
      }
    }
    return targets;
  }

  /// إيقاف الابتلاع
  void stopConsuming() => _isConsuming = false;

  Future<String?> _getSubnet() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              return '${parts[0]}.${parts[1]}.${parts[2]}';
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
