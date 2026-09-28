import 'dart:io';
import 'dart:async';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();
  
  List<Map<String, dynamic>> _audioFiles = [];
  List<Map<String, dynamic>> _videoFiles = [];
  List<Map<String, dynamic>> _imageFiles = [];
  bool _isScanning = false;
  
  Future<void> scanMedia() async {
    _isScanning = true;
    
    _audioFiles.clear();
    _videoFiles.clear();
    _imageFiles.clear();
    
    // Scan Music
    await _scanDirectory('/sdcard/Music', _audioFiles, ['.mp3', '.wav', '.ogg', '.m4a']);
    await _scanDirectory('/sdcard/Audio', _audioFiles, ['.mp3', '.wav', '.ogg', '.m4a']);
    await _scanDirectory('/storage/emulated/0/Music', _audioFiles, ['.mp3', '.wav', '.ogg', '.m4a']);
    
    // Scan Videos
    await _scanDirectory('/sdcard/Movies', _videoFiles, ['.mp4', '.avi', '.mkv', '.mov', '.3gp']);
    await _scanDirectory('/sdcard/DCIM', _videoFiles, ['.mp4', '.mov']);
    
    // Scan Images
    await _scanDirectory('/sdcard/DCIM', _imageFiles, ['.jpg', '.jpeg', '.png', '.gif', '.bmp']);
    await _scanDirectory('/sdcard/Pictures', _imageFiles, ['.jpg', '.jpeg', '.png', '.gif']);
    await _scanDirectory('/sdcard/Download', _imageFiles, ['.jpg', '.jpeg', '.png']);
    
    _isScanning = false;
  }
  
  Future<void> _scanDirectory(String path, List<Map<String, dynamic>> list, List<String> extensions) async {
    final dir = Directory(path);
    if (!await dir.exists()) return;
    
    try {
      final files = await dir.list().toList();
      for (final file in files) {
        if (file is File) {
          final ext = file.path.toLowerCase();
          if (extensions.any((e) => ext.endsWith(e))) {
            final stat = await file.stat();
            list.add({
              'name': file.path.split('/').last,
              'path': file.path,
              'size': stat.size,
              'modified': stat.modified,
            });
          }
        }
      }
    } catch (_) {}
  }
  
  List<Map<String, dynamic>> getAudioFiles() => _audioFiles;
  List<Map<String, dynamic>> getVideoFiles() => _videoFiles;
  List<Map<String, dynamic>> getImageFiles() => _imageFiles;
  
  bool get isScanning => _isScanning;
  
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
