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

  Future<bool> loadModel(String path, {int threads = 4}) async {
    final ok = await _channel.invokeMethod<bool>('loadModel', {'path': path, 'threads': threads}) ?? false;
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
