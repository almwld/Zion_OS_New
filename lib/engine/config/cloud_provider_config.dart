class CloudProviderConfig {
  final String id;
  final String baseUrl;
  final String model;
  final String apiKey;

  const CloudProviderConfig({
    required this.id,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  bool get isConfigured =>
      id.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      Uri.tryParse(baseUrl)?.hasAuthority == true;
}
