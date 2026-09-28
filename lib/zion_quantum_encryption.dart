import 'package:flutter/material.dart';
import 'dart:math';

class QuantumKey {
  final String id;
  final int length;
  final double entropy;
  final DateTime createdAt;
  bool distributed;

  QuantumKey({
    required this.id,
    required this.length,
    required this.entropy,
    required this.createdAt,
    this.distributed = false,
  });
}

class ZionQuantumEncryption extends ChangeNotifier {
  final List<QuantumKey> _generatedKeys = [];
  bool _isGenerating = false;
  bool _quantumChannelActive = false;
  double _qber = 0.0;

  List<QuantumKey> get generatedKeys => List.unmodifiable(_generatedKeys);
  bool get isGenerating => _isGenerating;
  bool get quantumChannelActive => _quantumChannelActive;
  double get qber => _qber;

  /// Generates cryptographically secure classical random material.
  /// This is NOT quantum key distribution and is labelled accordingly.
  Future<QuantumKey> generateQuantumKey({int length = 256}) async {
    if (length <= 0) throw ArgumentError.value(length, 'length');
    _isGenerating = true;
    notifyListeners();

    final random = Random.secure();
    var entropy = 0.0;
    for (var i = 0; i < 32; i++) {
      entropy += random.nextInt(256);
    }
    entropy /= (32 * 255);

    final key = QuantumKey(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      length: length,
      entropy: entropy,
      createdAt: DateTime.now(),
    );
    _generatedKeys.add(key);
    _isGenerating = false;
    notifyListeners();
    return key;
  }

  void toggleQuantumChannel() {
    // No QKD hardware/protocol endpoint is configured.
    _quantumChannelActive = false;
    _qber = 0.0;
    notifyListeners();
  }

  String encryptQuantum(String plaintext, QuantumKey key) {
    throw UnsupportedError(
      'التشفير الكمي غير متاح: لا يوجد تكامل QKD فعلي. استخدم CryptoSuite للتشفير التقليدي الآمن.',
    );
  }
}
