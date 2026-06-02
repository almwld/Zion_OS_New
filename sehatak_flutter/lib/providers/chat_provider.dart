import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class ChatProvider extends ChangeNotifier {
  static const String serverUrl = 'https://hi-g26z.onrender.com';
  
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _userId;
  final List<ChatMessage> _messages = [];

  bool get isConnected => _isConnected;
  List<ChatMessage> get messages => _messages;

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('phone') ?? 'unknown';

    _socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket!.connect();
    _socket!.emit('register', _userId);

    _socket!.onConnect((_) {
      _isConnected = true;
      notifyListeners();
      debugPrint('✅ Chat connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
    });

    _socket!.on('new_message', (data) {
      _messages.add(ChatMessage(
        id: DateTime.now().toString(),
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? '',
        text: data['text'] ?? '',
        timestamp: DateTime.now(),
        isMe: data['senderId'] == _userId,
      ));
      notifyListeners();
    });
  }

  void sendMessage(String receiverId, String text) {
    _socket?.emit('send_message', {
      'senderId': _userId,
      'senderName': 'مستخدم',
      'receiverId': receiverId,
      'text': text,
    });
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
