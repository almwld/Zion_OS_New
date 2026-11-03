import '../../ai/llama_service.dart';
import '../config/engine_config.dart';
import '../config/cloud_provider_config.dart';
import '../config/engine_mode.dart';
import 'ai_provider.dart';
import 'cloud_provider.dart';
import 'local_provider.dart';

class ProviderGeneration {
  final String text;
  final String provider;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final bool tokenCountsEstimated;
  final bool usedFallback;

  const ProviderGeneration({
    required this.text,
    required this.provider,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.tokenCountsEstimated,
    required this.usedFallback,
  });
}

class ProviderSelector {
  final EngineConfig config;
  final LlamaService llama;
  AIProvider? _current;
  EngineMode _mode = EngineMode.unset;
  final List<AIProvider> _cloudPool = <AIProvider>[];
  LocalProvider? _local;

  ProviderSelector({required this.config, required this.llama});

  AIProvider get current =>
      _current ?? (throw StateError('لم يتم اختيار مزود'));
  EngineMode get currentMode => _mode;
  bool get hasOptionalCloudProviders =>
      config.cloudProviders.isNotEmpty ||
      (config.cloudApiKey?.trim().isNotEmpty ?? false);

  LocalProvider _localProvider() =>
      _local ??= LocalProvider(llama: llama, modelPath: config.localModelPath);

  List<AIProvider> _configuredCloudProviders() {
    if (_cloudPool.isNotEmpty) return _cloudPool;
    final configured = config.cloudProviders;
    if (configured.isNotEmpty) {
      for (final CloudProviderConfig item in configured) {
        _cloudPool.add(CloudProvider(
          apiKey: item.apiKey,
          baseUrl: item.baseUrl,
          model: item.model,
        ));
      }
    } else if (config.cloudApiKey?.trim().isNotEmpty ?? false) {
      // Legacy settings remain explicitly opt-in. No API key or paid endpoint
      // is supplied by default and no cloud request is made automatically.
      _cloudPool.add(CloudProvider(
        apiKey: config.cloudApiKey!,
        baseUrl: config.cloudBaseUrl ?? 'https://api.openai.com/v1',
        model: config.cloudModel ?? 'gpt-4o-mini',
      ));
    }
    return _cloudPool;
  }

  Future<void> switchTo(EngineMode mode) async {
    if (mode == EngineMode.unset) {
      throw StateError('وضع التشغيل غير محدد');
    }
    final candidates = mode == EngineMode.local
        ? <AIProvider>[_localProvider()]
        : _configuredCloudProviders();
    if (candidates.isEmpty) {
      throw StateError(
        'لا يوجد مزود سحابي اختياري مهيأ؛ الاستخدام المحلي هو المسار الافتراضي المجاني',
      );
    }

    Object? lastError;
    AIProvider? ready;
    for (final candidate in candidates) {
      try {
        if (await candidate.isReady()) {
          ready = candidate;
          break;
        }
        lastError = StateError('المزود ${candidate.name} غير جاهز');
      } catch (error) {
        lastError = error;
      }
    }
    if (ready == null) {
      throw StateError('تعذر تهيئة أي مزود من المجموعة: $lastError');
    }

    // Transactional swap: a failed replacement leaves the active provider
    // intact. Providers stay alive until the selector is disposed.
    _current = ready;
    _mode = ready.mode;
  }

  Future<ProviderGeneration> generateTracked({
    required String prompt,
    String? systemPrompt,
    int? maxTokens,
    double temperature = 0.2,
    void Function(String chunk)? onChunk,
    Future<void>? cancellation,
  }) async {
    final active = current;
    final fullPrompt =
        systemPrompt == null ? prompt : '$systemPrompt\n\n$prompt';
    var usedFallback = false;
    var responseProvider = active;
    late String output;

    try {
      output = await active.generate(
        prompt: prompt,
        systemPrompt: systemPrompt,
        maxTokens: maxTokens,
        temperature: temperature,
        onChunk: onChunk,
        cancellation: cancellation,
      );
    } catch (_) {
      if (active.mode != EngineMode.cloud) rethrow;
      final local = _localProvider();
      if (!await local.isReady()) rethrow;
      output = await local.generate(
        prompt: prompt,
        systemPrompt: systemPrompt,
        maxTokens: maxTokens,
        temperature: temperature,
        onChunk: onChunk,
        cancellation: cancellation,
      );
      responseProvider = local;
      _current = local;
      _mode = EngineMode.local;
      usedFallback = true;
    }

    // Counts are estimates until a provider supplies normalized usage data.
    final inputTokens = _estimateTokens(fullPrompt);
    final outputTokens = _estimateTokens(output);
    return ProviderGeneration(
      text: output,
      provider: responseProvider.name,
      model: responseProvider.mode == EngineMode.local
          ? 'local-model'
          : responseProvider.name,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      tokenCountsEstimated: true,
      usedFallback: usedFallback,
    );
  }

  int _estimateTokens(String value) => (value.runes.length / 4).ceil();

  Future<void> dispose() async {
    final providers = <AIProvider>{..._cloudPool};
    if (_local != null) providers.add(_local!);
    for (final provider in providers) {
      await provider.dispose();
    }
    _cloudPool.clear();
    _local = null;
    _current = null;
    _mode = EngineMode.unset;
  }
}
