import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String callerName;
  final bool isVideo;
  
  const CallScreen({
    super.key,
    required this.channelName,
    required this.callerName,
    this.isVideo = true,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoOn = true;
  bool _isCallConnected = true;
  Duration _callDuration = Duration.zero;
  
  @override
  void initState() {
    super.initState();
    _startCallTimer();
  }
  
  void _startCallTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isCallConnected && mounted) {
        setState(() => _callDuration += const Duration(seconds: 1));
        _startCallTimer();
      }
    });
  }
  
  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
  
  void _endCall() {
    setState(() => _isCallConnected = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // خلفية المكالمة
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF16213E).withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),
            
            // صورة مصغرة لنفسك
            if (widget.isVideo && _isVideoOn)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    color: const Color(0xFF0F3460),
                  ),
                  child: const Center(
                    child: Icon(Icons.videocam, color: Colors.white70, size: 40),
                  ),
                ),
              ),
            
            // معلومات المتصل
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.callerName[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isCallConnected ? _formatDuration(_callDuration) : 'انتهت المكالمة',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (_isCallConnected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record, color: AppColors.success, size: 8),
                            SizedBox(width: 4),
                            Text('متصل', style: TextStyle(color: AppColors.success, fontSize: 10)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // أزرار التحكم
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlBtn(Icons.mic, _isMuted ? AppColors.error : Colors.white70, 'الميك', () {
                    setState(() => _isMuted = !_isMuted);
                  }),
                  _controlBtn(_isSpeakerOn ? Icons.volume_up : Icons.volume_off, Colors.white70, 'الصوت', () {
                    setState(() => _isSpeakerOn = !_isSpeakerOn);
                  }),
                  if (widget.isVideo)
                    _controlBtn(_isVideoOn ? Icons.videocam : Icons.videocam_off, _isVideoOn ? Colors.white70 : AppColors.error, 'الفيديو', () {
                      setState(() => _isVideoOn = !_isVideoOn);
                    }),
                  // زر إنهاء المكالمة
                  GestureDetector(
                    onTap: _endCall,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 4),
                        const Text('إنهاء', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                  if (widget.isVideo)
                    _controlBtn(Icons.cameraswitch, Colors.white70, 'تبديل', () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _controlBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
