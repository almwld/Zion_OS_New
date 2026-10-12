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
    if (path.trim().isEmpty) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('loadModel', {
        'path': path,
        'threads': threads.clamp(1, 4),
        if (loraPath != null && loraPath.isNotEmpty) 'loraPath': loraPath,
        'loraScale': loraScale > 0 ? loraScale : 1.0,
      }) ?? false;
      _loaded = ok;
      _modelPath = ok ? path : null;
      return ok;
    } on PlatformException {
      _loaded = false;
      _modelPath = null;
      return false;
    } on MissingPluginException {
      _loaded = false;
      _modelPath = null;
      return false;
    }
  }

  Future<String> generate(String prompt, {int maxTokens = 512, double temperature = 0.7}) async {
    if (!_loaded) return 'ERROR: النموذج المحلي غير محمل.';
    final input = prompt.length > 6000 ? prompt.substring(0, 6000) : prompt;
    final tokenLimit = maxTokens.clamp(1, 256);
    try {
      return (await _channel.invokeMethod<String>('generate', {
        'prompt': input,
        'maxTokens': tokenLimit,
        'temperature': temperature.clamp(0.0, 1.0),
      })) ?? 'ERROR: لم يصل رد من المحرك المحلي.';
    } on PlatformException catch (error) {
      return 'ERROR: تعذرت المعالجة المحلية: ${error.message ?? error.code}';
    } on MissingPluginException {
      return 'ERROR: محرك الذكاء الاصطناعي المحلي غير متاح في هذا البناء.';
    }
  }

  Future<void> unloadModel() async {
    try {
      await _channel.invokeMethod('freeModel');
    } on PlatformException {
      // The engine may already have been released during activity teardown.
    } on MissingPluginException {
      // Unit tests and unsupported runtimes have no native AI bridge.
    } finally {
      _loaded = false;
      _modelPath = null;
    }
  }

  Future<bool> get nativeLoaded async {
    try {
      return await _channel.invokeMethod<bool>('isLoaded') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String> get engineVersion async {
    try {
      return await _channel.invokeMethod<String>('version') ?? 'unknown';
    } on PlatformException {
      return 'unavailable';
    } on MissingPluginException {
      return 'unavailable';
    }
  }
}
