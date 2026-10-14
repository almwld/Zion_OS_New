import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Local gallery launcher. Uses Android's system photo picker so it displays
/// actual user-selected media without requesting broad storage access.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = <XFile>[];
  bool _isLoading = false;
  String? _error;

  Future<void> _addPhotos() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final selected = await _picker.pickMultiImage(imageQuality: 100);
      if (!mounted) return;
      if (selected.isNotEmpty) {
        final known = _photos.map((file) => file.path).toSet();
        setState(() {
          _photos.addAll(selected.where((file) => !known.contains(file.path)));
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'تعذر فتح منتقي الصور: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _viewPhoto(XFile photo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  tooltip: 'إغلاق الصورة',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5,
                  child: Center(
                    child: Image.file(
                      File(photo.path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'تعذر عرض هذه الصورة.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  photo.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00BCD4);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('الاستوديو', style: TextStyle(color: accent)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'إضافة صور من الجهاز',
            onPressed: _isLoading ? null : _addPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined, color: accent),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addPhotos,
        backgroundColor: accent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.photo_library_outlined),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : _photos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 64, color: Colors.white38),
                        const SizedBox(height: 12),
                        const Text(
                          'اختر الصور من مكتبة الجهاز لعرضها هنا.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _addPhotos,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('فتح الصور'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                        ],
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return Semantics(
                      button: true,
                      label: photo.name,
                      child: GestureDetector(
                        onTap: () => _viewPhoto(photo),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(photo.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFF172126),
                              child: Icon(Icons.broken_image_outlined, color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
