import 'dart:async';
import 'dart:io';

/// Discovers media in common shared-storage folders.
///
/// Android scoped storage may hide folders from direct filesystem access. This
/// service therefore reports scan errors instead of claiming the device was
/// fully indexed. Use the system photo picker for media outside these folders.
class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  static const int _maxDepth = 4;
  static const int _maxEntries = 6000;

  final List<Map<String, dynamic>> _audioFiles = [];
  final List<Map<String, dynamic>> _videoFiles = [];
  final List<Map<String, dynamic>> _imageFiles = [];
  final List<String> _scanErrors = [];
  bool _isScanning = false;

  static const _audioExtensions = <String>{
    '.mp3', '.wav', '.ogg', '.m4a', '.aac', '.flac', '.opus', '.wma',
  };
  static const _videoExtensions = <String>{
    '.mp4', '.m4v', '.avi', '.mkv', '.mov', '.3gp', '.webm', '.mpeg', '.mpg',
  };
  static const _imageExtensions = <String>{
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif',
  };

  Future<void> scanMedia() async {
    if (_isScanning) return;
    _isScanning = true;
    _audioFiles.clear();
    _videoFiles.clear();
    _imageFiles.clear();
    _scanErrors.clear();

    final seen = <String>{};
    var visited = 0;
    try {
      final roots = <String>[
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Audio',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Download',
        '/sdcard/Music',
        '/sdcard/Audio',
        '/sdcard/Movies',
        '/sdcard/DCIM',
        '/sdcard/Pictures',
        '/sdcard/Download',
      ];

      for (final root in roots) {
        if (visited >= _maxEntries) break;
        await _scanDirectory(
          Directory(root),
          depth: 0,
          seen: seen,
          onVisited: () => visited++,
        );
      }
    } finally {
      _isScanning = false;
    }
  }

  Future<void> _scanDirectory(
    Directory directory, {
    required int depth,
    required Set<String> seen,
    required void Function() onVisited,
  }) async {
    if (depth > _maxDepth) return;

    try {
      if (!await directory.exists()) return;
      await for (final entity in directory.list(
        recursive: false,
        followLinks: false,
      )) {
        onVisited();
        if (entity.path.split(Platform.pathSeparator).last.startsWith('.')) {
          continue;
        }

        try {
          final type = await FileSystemEntity.type(
            entity.path,
            followLinks: false,
          );
          if (type == FileSystemEntityType.directory) {
            await _scanDirectory(
              Directory(entity.path),
              depth: depth + 1,
              seen: seen,
              onVisited: onVisited,
            );
            continue;
          }
          if (type != FileSystemEntityType.file) continue;

          final path = entity.path;
          final normalized = Platform.isWindows ? path.toLowerCase() : path;
          if (!seen.add(normalized)) continue;

          final extension = _extensionOf(path);
          final target = _audioExtensions.contains(extension)
              ? _audioFiles
              : _videoExtensions.contains(extension)
                  ? _videoFiles
                  : _imageExtensions.contains(extension)
                      ? _imageFiles
                      : null;
          if (target == null) continue;

          final stat = await File(path).stat();
          target.add({
            'name': path.split(Platform.pathSeparator).last,
            'path': path,
            'size': stat.size,
            'modified': stat.modified,
          });
        } catch (error) {
          _recordError(entity.path, error);
        }
      }
    } catch (error) {
      _recordError(directory.path, error);
    }
  }

  String _extensionOf(String path) {
    final name = path.split(Platform.pathSeparator).last.toLowerCase();
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot);
  }

  void _recordError(String path, Object error) {
    if (_scanErrors.length < 100) {
      _scanErrors.add('$path: $error');
    }
  }

  List<Map<String, dynamic>> getAudioFiles() =>
      List.unmodifiable(_audioFiles);
  List<Map<String, dynamic>> getVideoFiles() =>
      List.unmodifiable(_videoFiles);
  List<Map<String, dynamic>> getImageFiles() =>
      List.unmodifiable(_imageFiles);
  List<String> get scanErrors => List.unmodifiable(_scanErrors);
  bool get isScanning => _isScanning;

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
