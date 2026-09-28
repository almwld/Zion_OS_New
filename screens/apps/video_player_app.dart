import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerApp extends StatefulWidget {
  const VideoPlayerApp({super.key});
  @override
  State<VideoPlayerApp> createState() => _VideoPlayerAppState();
}

class _VideoPlayerAppState extends State<VideoPlayerApp> {
  final TextEditingController _urlController = TextEditingController();
  VideoPlayerController? _controller;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openUrl() async {
    final raw = _urlController.text.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      setState(() => _error = 'أدخل رابط فيديو صالحاً يبدأ بـ http أو https.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final old = _controller;
    _controller = null;
    await old?.dispose();
    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      if (!mounted) { await controller.dispose(); return; }
      setState(() { _controller = controller; _loading = false; });
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تشغيل الفيديو. تحقق من الرابط واتصال الشبكة.';
      });
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller?.value.isInitialized == true;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Player', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: initialized ? controller!.value.aspectRatio : 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF101418),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: initialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(controller!),
                        IconButton(
                          onPressed: _togglePlayback,
                          iconSize: 64,
                          color: Colors.white,
                          icon: Icon(controller.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled),
                        ),
                      ],
                    )
                  : Center(
                      child: _loading
                          ? const CircularProgressIndicator(color: Color(0xFF00BCD4))
                          : const Icon(Icons.video_library_outlined, color: Colors.white38, size: 64),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _openUrl(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'رابط الفيديو',
              hintText: 'https://example.com/video.mp4',
              labelStyle: const TextStyle(color: Color(0xFF00BCD4)),
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                onPressed: _loading ? null : _openUrl,
                icon: const Icon(Icons.play_arrow, color: Color(0xFF00BCD4)),
                tooltip: 'تشغيل',
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          if (initialized) ...[
            const SizedBox(height: 12),
            VideoProgressIndicator(
              controller!,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              colors: const VideoProgressColors(
                playedColor: Color(0xFF00BCD4),
                bufferedColor: Color(0xFF607D8B),
                backgroundColor: Colors.white24,
              ),
            ),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (_, value, __) => Text(
                value.position.inMinutes.toString() + ':' +
                    value.position.inSeconds.remainder(60).toString().padLeft(2, '0') +
                    ' / ' +
                    value.duration.inMinutes.toString() + ':' +
                    value.duration.inSeconds.remainder(60).toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'لا توجد فيديوهات تجريبية مضمنة. أضف رابط وسائط حقيقي لتشغيله.',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
