import 'security_result.dart';

class SecurityEvent {
  const SecurityEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.result,
    this.assetId,
    this.attributes = const <String, Object?>{},
  });

  final String id;
  final DateTime timestamp;
  final String type;
  final SecurityResult result;
  final String? assetId;
  final Map<String, Object?> attributes;

  SecuritySeverity get severity => result.severity;
  ResultSource get source => result.source;
}
