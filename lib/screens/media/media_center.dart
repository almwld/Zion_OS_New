import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../core/services/media_service.dart';

class MediaCenter extends StatefulWidget {
  const MediaCenter({super.key});

  @override
  State<MediaCenter> createState() => _MediaCenterState();
}

class _MediaCenterState extends State<MediaCenter>
    with SingleTickerProviderStateMixin {
  final MediaService _mediaService = MediaService();
  late final TabController _tabController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      await _mediaService.scanMedia();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'تعذر فحص ملفات الوسائط: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00BCD4);
    return Scaffold(
      backgroundColor: const Color(0xFF080D12),
      appBar: AppBar(
        title: const Text('Media Center', style: TextStyle(color: accent)),
        backgroundColor: const Color(0xFF080D12),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accent),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'إعادة فحص الوسائط',
            onPressed: _isLoading ? null : _loadMedia,
            icon: const Icon(Icons.refresh, color: accent),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: accent,
          unselectedLabelColor: Colors.white54,
          indicatorColor: accent,
          tabs: const [
            Tab(icon: Icon(Icons.audiotrack), text: 'Music'),
            Tab(icon: Icon(Icons.videocam), text: 'Videos'),
            Tab(icon: Icon(Icons.image), text: 'Images'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMusicTab(),
                    _buildVideosTab(),
                    _buildImagesTab(),
                  ],
                ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadMedia,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );

  Widget _buildMusicTab() {
    final files = _mediaService.getAudioFiles();
    if (files.isEmpty) {
      return _emptyState(
        Icons.audiotrack,
        'لا توجد ملفات صوتية يمكن الوصول إليها.',
        'قد تكون بعض مجلدات الجهاز محمية بواسطة Scoped Storage.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _mediaTile(
          icon: Icons.audiotrack,
          file: file,
          onTap: () => _openAudio(file),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    final files = _mediaService.getVideoFiles();
    if (files.isEmpty) {
      return _emptyState(Icons.video_library_outlined,
          'لا توجد فيديوهات يمكن الوصول إليها.', null);
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openVideo(file),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _tileDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline,
                    color: Color(0xFF00BCD4), size: 48),
                const SizedBox(height: 8),
                Text(file['name'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                Text(_mediaService.formatSize(file['size'] as int),
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagesTab() {
    final files = _mediaService.getImageFiles();
    if (files.isEmpty) {
      return _emptyState(Icons.photo_library_outlined,
          'لا توجد صور يمكن الوصول إليها.', null);
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return InkWell(
          onTap: () => _openImage(file),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.file(
              File(file['path'] as String),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.white10,
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.white54, size: 32),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mediaTile({
    required IconData icon,
    required Map<String, dynamic> file,
    required VoidCallback onTap,
  }) {
    final modified = file['modified'] as DateTime;
    return Card(
      color: Colors.white.withOpacity(0.045),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00BCD4), size: 30),
        title: Text(file['name'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '${_mediaService.formatSize(file['size'] as int)} • ${modified.day}/${modified.month}/${modified.year}',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: const Icon(Icons.open_in_new, color: Color(0xFF00BCD4)),
        onTap: onTap,
      ),
    );
  }

  BoxDecoration _tileDecoration() => BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.25)),
      );

  Widget _emptyState(IconData icon, String title, String? detail) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 58, color: Colors.white24),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              if (detail != null) ...[
                const SizedBox(height: 8),
                Text(detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadMedia,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة الفحص'),
              ),
            ],
          ),
        ),
      );

  Future<void> _openAudio(Map<String, dynamic> file) async {
    final path = file['path'] as String;
    final target = File(path);
    if (!await target.exists()) {
      if (mounted) _showMessage('الملف لم يعد موجوداً. أعد فحص الوسائط.');
      return;
    }
    try {
      final opened = await launchUrl(
        Uri.file(path),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showMessage('لا يوجد تطبيق خارجي مسجل لفتح هذا الملف الصوتي.');
      }
    } catch (error) {
      if (mounted) _showMessage('تعذر فتح الملف الصوتي: $error');
    }
  }

  Future<void> _openVideo(Map<String, dynamic> file) async {
    final path = file['path'] as String;
    if (!await File(path).exists()) {
      if (mounted) _showMessage('الفيديو غير موجود. أعد فحص الوسائط.');
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _LocalVideoDialog(path: path, title: file['name'] as String),
    );
  }

  Future<void> _openImage(Map<String, dynamic> file) async {
    final path = file['path'] as String;
    if (!await File(path).exists()) {
      if (mounted) _showMessage('الصورة غير موجودة. أعد فحص الوسائط.');
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(file['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 6,
                  child: Center(
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'تعذر عرض الصورة.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LocalVideoDialog extends StatefulWidget {
  const _LocalVideoDialog({required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<_LocalVideoDialog> createState() => _LocalVideoDialogState();
}

class _LocalVideoDialogState extends State<_LocalVideoDialog> {
  VideoPlayerController? _controller;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    VideoPlayerController? candidate;
    try {
      candidate = VideoPlayerController.file(File(widget.path));
      await candidate.initialize();
      if (!mounted) {
        await candidate.dispose();
        return;
      }
      setState(() {
        _controller = candidate;
        _loading = false;
      });
      await candidate.play();
    } catch (error) {
      await candidate?.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تهيئة مشغل الفيديو: $error';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller?.value.isInitialized == true;
    return Dialog(
      backgroundColor: const Color(0xFF080D12),
      insetPadding: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.movie_outlined, color: Color(0xFF00BCD4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            AspectRatio(
              aspectRatio: ready ? controller!.value.aspectRatio : 16 / 9,
              child: Container(
                color: Colors.black,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00BCD4)))
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.redAccent)),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(controller!),
                              IconButton(
                                iconSize: 58,
                                color: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    if (controller.value.isPlaying) {
                                      controller.pause();
                                    } else {
                                      controller.play();
                                    }
                                  });
                                },
                                icon: Icon(controller.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled),
                              ),
                            ],
                          ),
              ),
            ),
            if (ready)
              VideoProgressIndicator(
                controller!,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF00BCD4),
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
