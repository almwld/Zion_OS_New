import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/services/camera_service.dart';

class CameraCenter extends StatefulWidget {
  const CameraCenter({super.key});

  @override
  State<CameraCenter> createState() => _CameraCenterState();
}

class _CameraCenterState extends State<CameraCenter> {
  late CameraService _cameraService;
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    _photos = await _cameraService.getSavedPhotos();
    setState(() => _isLoading = false);
  }

  Future<void> _takePhoto() async {
    final photo = await _cameraService.captureImage();
    if (photo != null) {
      await _loadPhotos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved successfully'), backgroundColor: Color(0xFF00BCD4)),
      );
    }
  }

  Future<void> _pickImages() async {
    final images = await _cameraService.pickImages();
    if (images.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${images.length} images selected'), backgroundColor: Color(0xFF00BCD4)),
      );
    }
  }

  Future<void> _deletePhoto(Map<String, dynamic> photo) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo', style: TextStyle(color: Color(0xFF00BCD4))),
        content: const Text('Are you sure you want to delete this photo?', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _cameraService.deletePhoto(photo['path']);
      await _loadPhotos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted'), backgroundColor: Color(0xFF00BCD4)),
      );
    }
  }

  void _showPhotoViewer(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image, color: Color(0xFF00BCD4), size: 80),
              const SizedBox(height: 16),
              Text(photo['name'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_cameraService.formatSize(photo['size']), style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _deletePhoto(photo);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Camera & Image Center', style: TextStyle(color: Color(0xFF00BCD4))),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00BCD4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Color(0xFF00BCD4)),
            onPressed: _takePhoto,
            tooltip: 'Take photo',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library, color: Color(0xFF00BCD4)),
            onPressed: _pickImages,
            tooltip: 'Pick images',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00BCD4)),
            onPressed: _loadPhotos,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
          : _photos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('No photos yet', style: TextStyle(color: Colors.white38)),
                      SizedBox(height: 8),
                      Text('Tap camera icon to take a photo', style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return GestureDetector(
                      onTap: () => _showPhotoViewer(photo),
                      onLongPress: () => _deletePhoto(photo),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
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
                                photo['name'],
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _cameraService.formatSize(photo['size']),
                              style: const TextStyle(color: Colors.white38, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
