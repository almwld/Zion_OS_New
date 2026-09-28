import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();
  
  final ImagePicker _picker = ImagePicker();
  
  Future<File?> captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final savedDir = Directory('${appDir.path}/photos');
        await savedDir.create(recursive: true);
        final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${savedDir.path}/$fileName');
        await File(image.path).copy(savedImage.path);
        return savedImage;
      }
    } catch (_) {}
    return null;
  }
  
  Future<File?> captureVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final savedDir = Directory('${appDir.path}/videos');
        await savedDir.create(recursive: true);
        final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final savedVideo = File('${savedDir.path}/$fileName');
        await File(video.path).copy(savedVideo.path);
        return savedVideo;
      }
    } catch (_) {}
    return null;
  }
  
  Future<List<XFile>> pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      return images;
    } catch (_) {
      return [];
    }
  }
  
  Future<void> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
  
  Future<List<Map<String, dynamic>>> getSavedPhotos() async {
    final photos = <Map<String, dynamic>>[];
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      if (await photosDir.exists()) {
        final files = await photosDir.list().toList();
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            photos.add({
              'path': file.path,
              'name': file.path.split('/').last,
              'size': stat.size,
              'created': stat.modified,
            });
          }
        }
      }
    } catch (_) {}
    return photos.reversed.toList();
  }
  
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
