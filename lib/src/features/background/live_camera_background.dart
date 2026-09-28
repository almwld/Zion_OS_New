import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

class LiveCameraBackground extends StatefulWidget {
  final Widget child;
  final double blurIntensity;
  final double opacity;

  const LiveCameraBackground({
    super.key,
    required this.child,
    this.blurIntensity = 5.0,
    this.opacity = 0.7,
  });

  @override
  State<LiveCameraBackground> createState() => _LiveCameraBackgroundState();
}

class _LiveCameraBackgroundState extends State<LiveCameraBackground> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00FF41), Colors.black],
          ),
        ),
        child: widget.child,
      );
    }

    return Stack(
      children: [
        // خلفية الكاميرا الحية
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: widget.blurIntensity, sigmaY: widget.blurIntensity),
              child: Opacity(
                opacity: widget.opacity,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
        ),
        // المحتوى الرئيسي
        widget.child,
      ],
    );
  }
}
