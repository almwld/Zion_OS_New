import 'cloud_provider_config.dart';
import 'engine_mode.dart';

class EngineConfig {
  final EngineMode defaultMode;
  final String? localModelPath, cloudApiKey, cloudBaseUrl, cloudModel;
  final String? githubToken, githubOwner, githubRepo;
  final List<CloudProviderConfig> cloudProviders;
  final int maxStepsPerTask, maxTokensPerStep, maxRepairCycles;
  final Duration maxTaskDuration, buildTimeout, buildPollInterval;
  final bool requireApprovalForWrite, requireApprovalForNetwork;

  const EngineConfig({
    this.defaultMode = EngineMode.local,
    this.localModelPath,
    this.cloudApiKey,
    this.cloudBaseUrl = 'https://api.openai.com/v1',
    this.cloudModel = 'gpt-4o-mini',
    this.cloudProviders = const [],
    this.githubToken,
    this.githubOwner,
    this.githubRepo,
    this.maxStepsPerTask = 30,
    this.maxTokensPerStep = 1200,
    this.maxRepairCycles = 5,
    this.maxTaskDuration = const Duration(minutes: 30),
    this.buildTimeout = const Duration(minutes: 30),
    this.buildPollInterval = const Duration(seconds: 30),
    this.requireApprovalForWrite = true,
    this.requireApprovalForNetwork = false,
  });

  List<String> validate() {
    final errors = <String>[];
    if (maxStepsPerTask < 1 || maxStepsPerTask > 100) {
      errors.add('maxStepsPerTask خارج النطاق');
    }
    if (maxTokensPerStep < 64) errors.add('maxTokensPerStep يجب ألا يقل عن 64');
    if (maxRepairCycles < 0 || maxRepairCycles > 5) {
      errors.add('maxRepairCycles يجب أن يكون بين 0 و5');
    }
    if (defaultMode == EngineMode.cloud &&
        cloudProviders.where((provider) => provider.isConfigured).isEmpty &&
        (cloudApiKey?.trim().isEmpty ?? true)) {
      errors.add('يجب تهيئة مزود سحابي اختيارياً قبل تفعيله');
    }
    if (cloudProviders.any((provider) => !provider.isConfigured)) {
      errors.add('إعداد أحد المزودات السحابية غير مكتمل');
    }
    if (githubToken != null && (githubOwner == null || githubRepo == null)) {
      errors.add('إعداد GitHub يحتاج owner وrepo');
    }
    return errors;
  }
}
