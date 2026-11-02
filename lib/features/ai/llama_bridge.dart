import '../../ai/llama_service.dart' as core;

/// Compatibility facade used by older AI-center screens. All model work is
/// delegated to the process-wide service-backed implementation so every UI
/// shares one native model session, recovery state, and foreground lifecycle.
class LlamaBridge {
  final core.LlamaService _service;
  LlamaBridge({core.LlamaService? service})
      : _service = service ?? core.LlamaService();

  Future<bool> isLoaded() => _service.refreshLoadedState();

  Future<void> load(String path) async {
    final loaded = await _service.loadModel(path);
    if (!loaded) {
      throw StateError('تعذر تحميل النموذج المحلي: $path');
    }
  }

  Future<String> generate(String prompt, {double temperature = .7}) {
    if (prompt.trim().isEmpty) return Future<String>.value('');
    return _service.generate(
      prompt,
      maxTokens: 512,
      temperature: temperature.clamp(0.0, 1.5).toDouble(),
    );
  }

  Future<void> free() => _service.unloadModel();
}
