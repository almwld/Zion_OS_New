import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';
import 'package:sehatak/presentation/screens/call/call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? doctorName;
  final String? doctorId;
  
  const ChatScreen({super.key, this.doctorName, this.doctorId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'مرحباً! كيف يمكنني مساعدتك اليوم؟', 'isMe': false, 'time': '10:30 ص'},
    {'text': 'أعاني من صداع متكرر في الجانب الأيمن', 'isMe': true, 'time': '10:31 ص'},
    {'text': 'هل الصداع يأتي في أوقات محددة؟ وهل هناك أعراض أخرى؟', 'isMe': false, 'time': '10:32 ص'},
    {'text': 'نعم، يأتي في المساء غالباً. وأحياناً أشعر بغثيان', 'isMe': true, 'time': '10:33 ص'},
    {'text': 'متى كانت آخر مرة قمت فيها بفحص العيون؟ قد يكون الصداع مرتبطاً بإجهاد العين', 'isMe': false, 'time': '10:34 ص'},
  ];
    
  bool _isTyping = false;

  String get _name => widget.doctorName ?? 'د. علي المولد';
  String get _status => _isTyping ? 'يكتب الآن...' : 'متصل 🟢';

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': _formatTime(DateTime.now()),
      });
    });
    _msgCtrl.clear();
    
    // محاكاة رد تلقائي
    _showTypingIndicator();
  }
  
  void _showTypingIndicator() {
    setState(() => _isTyping = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': 'شكراً لمشاركتك. سأراجع حالتك وأعطيك توصيتي قريباً.',
          'isMe': false,
          'time': _formatTime(DateTime.now()),
        });
      });
      _scrollToBottom();
    });
  }
  
  String _formatTime(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'م' : 'ص';
    return '$h:$m $period';
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _startCall({bool isVideo = true}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName: 'call_${DateTime.now().millisecondsSinceEpoch}',
          callerName: _name,
          isVideo: isVideo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _name[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(_status, style: TextStyle(fontSize: 11, color: _isTyping ? AppColors.warning : AppColors.success)),
              ],
            ),
          ],
        ),
        actions: [
          // زر المكالمة الصوتية
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.call, color: AppColors.success, size: 20),
            ),
            onPressed: () => _startCall(isVideo: false),
            tooltip: 'مكالمة صوتية',
          ),
          // زر مكالمة الفيديو
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.videocam, color: AppColors.info, size: 20),
            ),
            onPressed: () => _startCall(isVideo: true),
            tooltip: 'مكالمة فيديو',
          ),
        ],
      ),
      body: Column(
        children: [
          // مؤشر الكتابة
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.warning.withOpacity(0.1),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('$_name يكتب...', style: const TextStyle(color: AppColors.warning, fontSize: 12)),
                ],
              ),
            ),
          // قائمة الرسائل
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : null,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'],
                          style: TextStyle(
                            color: isMe ? Colors.white70 : AppColors.grey,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // حقل الإدخال
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: AppColors.grey),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _msgCtrl.text.trim().isNotEmpty
                          ? [AppColors.primary, AppColors.primaryDark]
                          : [AppColors.grey, AppColors.grey],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _msgCtrl.text.trim().isNotEmpty ? _sendMessage : null,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
