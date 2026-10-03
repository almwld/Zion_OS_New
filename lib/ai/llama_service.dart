import 'package:flutter/services.dart';

class LlamaModel {
  final String name;
  final String path;
  final int sizeBytes;
  final bool readable;
  const LlamaModel({required this.name, required this.path, required this.sizeBytes, required this.readable});
  factory LlamaModel.fromMap(Map<dynamic, dynamic> map) => LlamaModel(
    name: map['name']?.toString() ?? 'GGUF',
    path: map['path']?.toString() ?? '',
    sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
    readable: map['readable'] == true,
  );
}

class LlamaService {
  static const MethodChannel _channel = MethodChannel('zion.os/ai');
  bool _loaded = false;
  String? _modelPath;
  bool get isLoaded => _loaded;
  String? get currentModel => _modelPath;

  Future<List<LlamaModel>> discoverModels() async {
    final value = await _channel.invokeMethod<List<dynamic>>('discoverModels');
    return (value ?? const []).map((e) => LlamaModel.fromMap(Map<dynamic, dynamic>.from(e as Map))).toList();
  }

  Future<LlamaModel?> pickAndImportModel() async {
    final value = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickModel');
    if (value?['status'] != 'IMPORTED') return null;
    return LlamaModel.fromMap(value!);
  }

  /// Discover every readable GGUF exposed by the Android bridge and choose a
  /// practical chat/instruct model automatically. Preference is given to
  /// instruction/chat-tuned names, then to a moderate model size.
  Future<LlamaModel?> autoLoadBestModel({int threads = 4}) async {
    final models = (await discoverModels())
        .where((m) => m.readable && m.path.isNotEmpty)
        .toList();
    if (models.isEmpty) return null;

    int score(LlamaModel m) {
      final n = m.name.toLowerCase();
      var s = 0;
      if (n.contains('instruct')) s += 100;
      if (n.contains('chat')) s += 90;
      if (n.contains('assistant')) s += 70;
      if (n.contains('qwen')) s += 55;
      if (n.contains('llama')) s += 45;
      if (n.contains('tinyllama')) s += 35;
      if (n.contains('base')) s -= 25;
      // Prefer models in a mobile-friendly range without making size a hard
      // requirement; the native loader remains the final compatibility check.
      final gb = m.sizeBytes / (1024 * 1024 * 1024);
      if (gb >= 1.0 && gb <= 5.0) s += 25;
      if (gb > 8.0) s -= 20;
      return s;
    }

    models.sort((a, b) {
      final byScore = score(b).compareTo(score(a));
      if (byScore != 0) return byScore;
      return a.sizeBytes.compareTo(b.sizeBytes);
    });

    for (final model in models) {
      if (await loadModel(model.path, threads: threads)) return model;
    }
    return null;
  }

  Future<bool> loadModel(
    String path, {
    int threads = 4,
    String? loraPath,
    double loraScale = 1.0,
  }) async {
    final ok = await _channel.invokeMethod<bool>('loadModel', {
      'path': path,
      'threads': threads,
      if (loraPath != null && loraPath.isNotEmpty) 'loraPath': loraPath,
      'loraScale': loraScale > 0 ? loraScale : 1.0,
    }) ?? false;
    _loaded = ok;
    _modelPath = ok ? path : null;
    return ok;
  }

  Future<String> generate(String prompt, {int maxTokens = 512, double temperature = 0.7}) async {
    if (!_loaded) return 'ERROR: النموذج المحلي غير محمل.';
    return (await _channel.invokeMethod<String>('generate', {
      'prompt': prompt, 'maxTokens': maxTokens, 'temperature': temperature,
    })) ?? 'ERROR: لم يصل رد من المحرك المحلي.';
  }

  Future<void> unloadModel() async {
    await _channel.invokeMethod('freeModel');
    _loaded = false;
    _modelPath = null;
  }

  Future<bool> get nativeLoaded async => await _channel.invokeMethod<bool>('isLoaded') ?? false;
  Future<String> get engineVersion async => await _channel.invokeMethod<String>('version') ?? 'unknown';
}
