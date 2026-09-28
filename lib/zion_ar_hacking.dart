import 'package:flutter/material.dart';

class ARTarget {
  final String id;
  final String name;
  final String type;
  final double distance;
  final int signalStrength;
  final List<String> vulnerabilities;

  ARTarget({
    required this.id,
    required this.name,
    required this.type,
    required this.distance,
    required this.signalStrength,
    required this.vulnerabilities,
  });
}

class ZionARHacking extends ChangeNotifier {
  bool _isScanning = false;
  final List<ARTarget> _targets = [];
  bool _arMode = false;
  String _cameraView = 'back';

  List<ARTarget> get targets => List.unmodifiable(_targets);
  bool get isScanning => _isScanning;
  bool get arMode => _arMode;

  void toggleARMode() {
    _arMode = !_arMode;
    notifyListeners();
  }

  /// Device discovery must come from a real supported sensor/radio integration.
  /// This legacy AR hacking service has no such integration and therefore
  /// intentionally returns no invented devices or vulnerabilities.
  Future<void> startARScan() async {
    _isScanning = true;
    _targets.clear();
    notifyListeners();
    _isScanning = false;
    notifyListeners();
  }

  void attackTarget(ARTarget target) {
    // Intentionally unavailable: no offensive actions are performed.
  }
}
