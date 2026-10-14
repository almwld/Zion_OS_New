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
    sizeBytes: num.tryParse(map['sizeBytes']?.toString() ?? '')?.toInt() ?? 0,
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
  Future<LlamaModel?> autoLoadBestModel({
    int threads = 2,
    int maxModelBytes = 2 * 1024 * 1024 * 1024,
  }) async {
    final models = (await discoverModels())
        .where((m) =>
            m.readable &&
            m.path.isNotEmpty &&
            m.sizeBytes > 0 &&
            m.sizeBytes <= maxModelBytes)
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
      // Prefer models in a practical mobile range. Oversized models are
      // filtered before scoring to reduce avoidable low-memory process deaths.
      final gb = m.sizeBytes / (1024 * 1024 * 1024);
      if (gb >= 0.5 && gb <= 2.0) s += 25;
      if (gb > 1.5) s -= 10;
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
    int threads = 2,
    String? loraPath,
    double loraScale = 1.0,
  }) async {
    if (path.trim().isEmpty) return false;
    // The native bridge releases the previous model before loading a new one.
    // Clear cached state first so an exception cannot leave stale "loaded" data.
    _loaded = false;
    _modelPath = null;
    try {
      final ok = await _channel.invokeMethod<bool>('loadModel', {
        'path': path,
        'threads': threads.clamp(1, 2),
        if (loraPath != null && loraPath.isNotEmpty) 'loraPath': loraPath,
        'loraScale': loraScale > 0 ? loraScale : 1.0,
      }) ?? false;
      _loaded = ok;
      _modelPath = ok ? path : null;
      return ok;
    } catch (_) {
      _loaded = false;
      _modelPath = null;
      rethrow;
    }
  }

  /// Synchronize this service instance with the native singleton. The model may
  /// have been loaded from the Offline AI screen using another Dart service instance.
  Future<bool> refreshLoadedState() async {
    try {
      final loaded = await nativeLoaded;
      _loaded = loaded;
      if (!loaded) _modelPath = null;
      return loaded;
    } catch (_) {
      return _loaded;
    }
  }

  Future<String> generate(String prompt, {int maxTokens = 128, double temperature = 0.25}) async {
    if (!await refreshLoadedState()) return 'ERROR: النموذج المحلي غير محمل.';
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
