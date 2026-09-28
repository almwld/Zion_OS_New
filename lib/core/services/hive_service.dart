import 'dart:async';
import 'dart:io';
import 'dart:convert';

class HiveService {
  ServerSocket? _server;
  final List<Socket> _drones = [];
  final List<Map<String, dynamic>> _missions = [];
  bool _isController = false;
  bool _isDrone = false;

  /// تشغيل الخلية كـ"قائد" (Controller)
  Future<void> startController({int port = 8888}) async {
    _isController = true;
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('Controller listening on port $port');

    _server!.listen((socket) {
      _drones.add(socket);
      print('Drone connected: ${socket.remoteAddress}');

      socket.listen((data) {
        final message = utf8.decode(data);
        _handleDroneMessage(socket, message);
      }, onDone: () {
        _drones.remove(socket);
        print('Drone disconnected');
      });
    });
  }

  /// تشغيل الخلية كـ"جندي" (Drone)
  Future<void> connectToController(String host, {int port = 8888}) async {
    _isDrone = true;
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      print('Connected to controller: $host');

      socket.listen((data) {
        final message = utf8.decode(data);
        _handleControllerMessage(socket, message);
      });
    } catch (e) {
      print('Failed to connect to controller: $e');
    }
  }

  /// إرسال مهمة لجميع الجنود
  void broadcastMission(String command, {String? target}) {
    if (!_isController) return;

    final mission = jsonEncode({
      'type': 'mission',
      'command': command,
      'target': target,
      'timestamp': DateTime.now().toIso8601String(),
    });

    for (final drone in _drones) {
      try {
        drone.write(mission);
      } catch (_) {}
    }

    _missions.add({
      'command': command,
      'target': target,
      'drones': _drones.length,
      'time': DateTime.now(),
    });
  }

  /// الحصول على تقرير المهمات
  List<Map<String, dynamic>> getMissionLog() => _missions;

  /// الحصول على عدد الجنود المتصلين
  int get connectedDrones => _drones.length;
  bool get isController => _isController;
  bool get isDrone => _isDrone;

  void _handleDroneMessage(Socket drone, String message) {
    final data = jsonDecode(message);
    if (data['type'] == 'result') {
      print('Mission result from ${drone.remoteAddress}: ${data['result']}');
      _missions.add({
        'drone': drone.remoteAddress.toString(),
        'result': data['result'],
        'time': DateTime.now(),
      });
    }
  }

  void _handleControllerMessage(Socket controller, String message) async {
    final data = jsonDecode(message);
    if (data['type'] == 'mission') {
      print('Received mission: ${data['command']} on ${data['target']}');
      
      // Execute the mission (import your unified_core_service here in a real app)
      final result = 'Drone executed ${data['command']} on ${data['target']}';
      
      controller.write(jsonEncode({
        'type': 'result',
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  /// إيقاف الخدمة
  void dispose() {
    _server?.close();
    for (final drone in _drones) {
      drone.destroy();
    }
    _drones.clear();
    _missions.clear();
  }
}
