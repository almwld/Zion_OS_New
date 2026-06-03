import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../../core/services/agora_service.dart';

class ChatScreen extends StatefulWidget {
  final String doctorName;
  final String channelName;
  
  const ChatScreen({super.key, this.doctorName = 'الطبيب', this.channelName = 'sehatak_channel'});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AgoraService _agora = AgoraService();
  final TextEditingController _msgCtrl = TextEditingController();
  final List<String> _messages = [];
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await _agora.initialize();
  }

  Future<void> _startCall({bool video = false}) async {
    setState(() { _isInCall = true; _isVideo = video; });
    await _agora.joinChannel(widget.channelName);
  }

  Future<void> _endCall() async {
    await _agora.leaveChannel();
    setState(() => _isInCall = false);
  }

  void _sendMessage() {
    if (_msgCtrl.text.isEmpty) return;
    setState(() => _messages.add(_msgCtrl.text));
    _msgCtrl.clear();
  }

  @override
  void dispose() {
    _agora.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorName),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () => _startCall()),
          IconButton(icon: const Icon(Icons.videocam), onPressed: () => _startCall(video: true)),
        ],
      ),
      body: Column(
        children: [
          if (_isInCall) _buildCallUI(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => Align(
                alignment: i % 2 == 0 ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: i % 2 == 0 ? Colors.teal[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_messages[i]),
                ),
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildCallUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black87,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white, size: 40), onPressed: () async {
          setState(() => _isMuted = !_isMuted);
          await _agora.engine?.muteLocalAudioStream(_isMuted);
        }),
        const SizedBox(width: 30),
        IconButton(icon: const Icon(Icons.call_end, color: Colors.red, size: 40), onPressed: _endCall),
        const SizedBox(width: 30),
        if (_isVideo) IconButton(icon: const Icon(Icons.videocam, color: Colors.white, size: 40), onPressed: () {}),
      ]),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _msgCtrl,
            textAlign: TextAlign.right,
            decoration: InputDecoration(hintText: 'اكتب رسالة...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(backgroundColor: Colors.teal, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage)),
      ]),
    );
  }
}
