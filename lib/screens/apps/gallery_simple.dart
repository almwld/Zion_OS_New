import 'package:flutter/material.dart';

import 'gallery_app.dart' as media_gallery;

/// Backward-compatible entry point for older launchers.
/// The real gallery uses the system photo picker and never displays demo items.
class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) => const media_gallery.GalleryApp();
}
