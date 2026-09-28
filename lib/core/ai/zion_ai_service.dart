import '../../security/core/security_core.dart';
import 'si_agent.dart';

/// Local AI facade for Arsenal and defensive runtime consumers.
class ZionAiService {
  ZionAiService({SecurityCore? securityCore})
      : securityCore = securityCore ?? SecurityCore();

  final SecurityCore securityCore;
  final SiAgent agent = SiAgent();

  Map<String, dynamic> analyzeSecurity({
    required double openPorts,
    required double anomalies,
    required double authFailures,
    required double encryptedTraffic,
  }) {
    final result = agent.analyzeSecurity(
      openPorts: openPorts,
      anomalies: anomalies,
      authFailures: authFailures,
      encryptedTraffic: encryptedTraffic,
    );
    securityCore.auditLogger.log(
      action: 'ai.security-analysis',
      actor: 'zion-ai',
      outcome: 'success',
      target: 'local-device',
      metadata: result,
    );
    return result;
  }

  Map<String, dynamic> forecast(List<double> values) {
    final result = agent.oracleForecast(values);
    securityCore.auditLogger.log(
      action: 'ai.forecast',
      actor: 'zion-ai',
      outcome: result['status'] == 'REAL' ? 'success' : 'unavailable',
      target: 'local-device',
      metadata: <String, Object?>{'observations': values.length},
    );
    return result;
  }

  Map<String, dynamic> guardian(List<String> indicators) {
    final result = agent.guardian(indicators);
    securityCore.auditLogger.log(
      action: 'ai.guardian',
      actor: 'zion-ai',
      outcome: result['status'] == 'ALERT' ? 'alert' : 'success',
      target: 'local-device',
      metadata: <String, Object?>{
        'indicatorCount': indicators.length,
        'action': result['action'],
      },
    );
    return result;
  }

  Map<String, dynamic> train(List<Map<String, dynamic>> feedback) {
    final result = agent.selfEvolve(feedback);
    securityCore.auditLogger.log(
      action: 'ai.self-evolve',
      actor: 'zion-ai',
      outcome: 'success',
      target: 'local-device',
      metadata: <String, Object?>{'trainedSamples': result['trainedSamples']},
    );
    return result;
  }
}
