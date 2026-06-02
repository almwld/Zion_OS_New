import 'package:flutter/material.dart';
import 'package:sehatak/core/constants/app_colors.dart';

class VoiceSearchScreen extends StatefulWidget {
  const VoiceSearchScreen({super.key});
  @override
  State<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends State<VoiceSearchScreen> with SingleTickerProviderStateMixin {
  bool _listening = false;
  String _result = '';
  late AnimationController _anim;

  @override
  void initState() { super.initState(); _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500)); }

  void _toggle() {
    setState(() {
      _listening = !_listening;
      if (_listening) { _anim.repeat(reverse: true); _result = ''; Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() { _listening = false; _anim.stop(); _result = 'طبيب قلب في صنعاء'; }); }); }
      else { _anim.stop(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بحث صوتي 🎤')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(animation: _anim, builder: (c, _) => Container(width: 120 + (_anim.value * 40), height: 120 + (_anim.value * 40), decoration: BoxDecoration(color: _listening ? AppColors.primary.withOpacity(0.1) : AppColors.primary.withOpacity(0.04), shape: BoxShape.circle), child: const Icon(Icons.mic, size: 60, color: AppColors.primary))),
        const SizedBox(height: 30),
        Text(_listening ? 'استمع... تكلم الآن 🎤' : 'اضغط على الميكروفون وتحدث', style: const TextStyle(fontSize: 16, color: AppColors.darkGrey)),
        if (_result.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.symmetric(horizontal: 30), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.success.withOpacity(0.2))), child: Row(children: [const Icon(Icons.check_circle, color: AppColors.success), const SizedBox(width: 8), Expanded(child: Text(_result, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)))])),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.search), label: const Text('عرض النتائج'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14))),
        ],
        const SizedBox(height: 40),
        GestureDetector(onTap: _toggle, child: Container(width: 70, height: 70, decoration: BoxDecoration(color: _listening ? AppColors.error : AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: (_listening ? AppColors.error : AppColors.primary).withOpacity(0.4), blurRadius: 16)]), child: Icon(_listening ? Icons.stop : Icons.mic, color: Colors.white, size: 32))),
      ])),
    );
  }
}
