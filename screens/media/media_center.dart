import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/services/media_service.dart';

class MediaCenter extends StatefulWidget {
  const MediaCenter({super.key});

  @override
  State<MediaCenter> createState() => _MediaCenterState();
}

class _MediaCenterState extends State<MediaCenter> with SingleTickerProviderStateMixin {
  late MediaService _mediaService;
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mediaService = MediaService();
    _loadMedia();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadMedia() async {
    await _mediaService.scanMedia();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Media Center', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: const [
            Tab(icon: Icon(Icons.audiotrack), text: 'Music'),
            Tab(icon: Icon(Icons.videocam), text: 'Videos'),
            Tab(icon: Icon(Icons.image), text: 'Images'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
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

  Widget _buildMusicTab() {
    final audioFiles = _mediaService.getAudioFiles();
    
    if (audioFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No audio files found', style: TextStyle(color: Colors.white38)),
            SizedBox(height: 8),
            Text('Place music in /Music or /Audio folder', style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: audioFiles.length,
      itemBuilder: (context, index) {
        final file = audioFiles[index];
        return _buildMediaTile(
          icon: Icons.audiotrack,
          name: file['name'],
          size: _mediaService.formatSize(file['size']),
          date: _formatDate(file['modified']),
          onTap: () => _showMediaPlayer(file),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    final videoFiles = _mediaService.getVideoFiles();
    
    if (videoFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No video files found', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: videoFiles.length,
      itemBuilder: (context, index) {
        final file = videoFiles[index];
        return GestureDetector(
          onTap: () => _showVideoPlayer(file),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam, color: Color(0xFF00BCD4), size: 48),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    file['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _mediaService.formatSize(file['size']),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagesTab() {
    final imageFiles = _mediaService.getImageFiles();
    
    if (imageFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No images found', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: imageFiles.length,
      itemBuilder: (context, index) {
        final file = imageFiles[index];
        return GestureDetector(
          onTap: () => _showImageViewer(file),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image, color: Color(0xFF00BCD4), size: 40),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    file['name'],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaTile({
    required IconData icon,
    required String name,
    required String size,
    required String date,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00BCD4), size: 32),
        title: Text(name, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$size • $date', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: const Icon(Icons.play_circle, color: Color(0xFF00BCD4)),
        onTap: onTap,
      ),
    );
  }

  void _showMediaPlayer(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file['name'], style: const TextStyle(color: Color(0xFF00BCD4))),
        content: SizedBox(
          width: 200,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_filled, color: Color(0xFF00BCD4), size: 48),
              const SizedBox(height: 16),
              Text('Playing audio file', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(_mediaService.formatSize(file['size']), style: const TextStyle(color: Colors.white38)),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _showVideoPlayer(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file['name'], style: const TextStyle(color: Color(0xFF00BCD4))),
        content: Container(
          width: 300,
          height: 200,
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_filled, color: Color(0xFF00BCD4), size: 64),
                SizedBox(height: 16),
                Text('Video player will open', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  void _showImageViewer(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image, color: Color(0xFF00BCD4), size: 100),
              const SizedBox(height: 16),
              Text(file['name'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_mediaService.formatSize(file['size']), style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.black),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
