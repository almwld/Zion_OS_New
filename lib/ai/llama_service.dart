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
    try {
      final value = await _channel.invokeMethod<List<dynamic>>('discoverModels');
      return (value ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => LlamaModel.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList(growable: false);
    } on PlatformException {
      return const <LlamaModel>[];
    } on MissingPluginException {
      return const <LlamaModel>[];
    } on FormatException {
      return const <LlamaModel>[];
    }
  }

  Future<LlamaModel?> pickAndImportModel() async {
    try {
      final value = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickModel');
      if (value?['status'] != 'IMPORTED') return null;
      return LlamaModel.fromMap(value!);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } on FormatException {
      return null;
    }
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
    if (path.trim().isEmpty || threads < 1) {
      _loaded = false;
      _modelPath = null;
      return false;
    }
    try {
      final ok = await _channel.invokeMethod<bool>('loadModel', {
        'path': path,
        'threads': threads.clamp(1, 8),
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
    if (prompt.trim().isEmpty) return '';
    if (!await refreshLoadedState()) return 'ERROR: النموذج المحلي غير محمل.';
    try {
      return (await _channel.invokeMethod<String>('generate', {
        'prompt': prompt,
        'maxTokens': maxTokens.clamp(1, 2048),
        'temperature': temperature.clamp(0.0, 2.0),
      })) ?? 'ERROR: لم يصل رد من المحرك المحلي.';
    } on PlatformException catch (e) {
      return 'ERROR: تعذر تشغيل النموذج المحلي: ${e.message ?? e.code}';
    } on MissingPluginException {
      return 'ERROR: محرك الذكاء الاصطناعي المحلي غير متاح على هذا البناء.';
    }
  }

  Future<void> unloadModel() async {
    try {
      await _channel.invokeMethod<void>('freeModel');
    } on PlatformException {
      // Native cleanup may already have happened during Activity teardown.
    } on MissingPluginException {
      // Keep teardown idempotent if the native AI bridge is not present.
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
