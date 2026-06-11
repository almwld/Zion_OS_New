import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  final List<Map<String, dynamic>> _photos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  int _selectedCategory = 0;
  
  final List<String> _categories = ['All', 'Camera', 'Screenshots', 'Downloads'];

  @override
  void initState() {
    super.initState();
    _loadSavedPhotos();
  }

  Future<void> _loadSavedPhotos() async {
    setState(() => _isLoading = true);
    // Simulate loading saved photos (actually we would scan directories)
    // For now, keep existing demo photos
    if (_photos.isEmpty) {
      _photos.addAll([
        {'name': 'IMG_20241201.jpg', 'size': '2.5 MB', 'date': '2024-12-01', 'path': '', 'type': 'image'},
        {'name': 'Screenshot_20241201.png', 'size': '0.8 MB', 'date': '2024-12-01', 'path': '', 'type': 'screenshot'},
      ]);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final file = File(photo.path);
        final stat = await file.stat();
        setState(() {
          _photos.insert(0, {
            'name': photo.name,
            'size': _formatSize(stat.size),
            'date': DateTime.now().toIso8601String().substring(0, 10),
            'path': photo.path,
            'type': 'camera',
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo captured'), backgroundColor: Color(0xFF00BCD4)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not available'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final file = File(image.path);
        final stat = await file.stat();
        setState(() {
          _photos.insert(0, {
            'name': image.name,
            'size': _formatSize(stat.size),
            'date': DateTime.now().toIso8601String().substring(0, 10),
            'path': image.path,
            'type': 'gallery',
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image added'), backgroundColor: Color(0xFF00BCD4)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image'), backgroundColor: Colors.red),
      );
    }
  }

  void _deletePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo', style: TextStyle(color: Color(0xFF00BCD4))),
        content: const Text('Are you sure you want to delete this photo?', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final photo = _photos[index];
              if (photo['path'] != null && photo['path'].isNotEmpty) {
                try {
                  await File(photo['path']).delete();
                } catch (_) {}
              }
              setState(() => _photos.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo deleted'), backgroundColor: Color(0xFF00BCD4)),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: photo['path'].isNotEmpty
                      ? Image.file(File(photo['path']), fit: BoxFit.contain)
                      : const Icon(Icons.image, size: 80, color: Color(0xFF00BCD4)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(photo['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Size: ${photo['size']} • Date: ${photo['date']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: photo['name']));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name copied'), backgroundColor: Color(0xFF00BCD4)),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Name'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final filteredPhotos = _selectedCategory == 0
        ? _photos
        : _selectedCategory == 1
            ? _photos.where((p) => p['type'] == 'camera').toList()
            : _selectedCategory == 2
                ? _photos.where((p) => p['type'] == 'screenshot').toList()
                : _photos.where((p) => p['type'] == 'gallery').toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Gallery', style: TextStyle(color: Color(0xFF00BCD4))),
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
            onPressed: _pickImage,
            tooltip: 'Pick from gallery',
          ),
        ],
        bottom: TabBar(
          onTap: (index) => setState(() => _selectedCategory = index),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00BCD4),
          tabs: _categories.map((cat) => Tab(text: cat)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
          : filteredPhotos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 64, color: Colors.white24),
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
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = filteredPhotos[index];
                    return GestureDetector(
                      onTap: () => _viewPhoto(photo),
                      onLongPress: () => _deletePhoto(_photos.indexOf(photo)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: photo['path'].isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(File(photo['path']), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                    )
                                  : const Icon(Icons.image, color: Colors.white, size: 40),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  photo['name'].split('.').last.toUpperCase(),
                                  style: const TextStyle(color: Colors.white70, fontSize: 8),
                                ),
                              ),
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
