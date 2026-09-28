import 'package:flutter_test/flutter_test.dart';

import 'package:project_zion/core/ai/zion_ai_service.dart';

void main() {
  test('local AI security analysis returns a bounded risk result', () {
    final ai = ZionAiService();
    final result = ai.analyzeSecurity(
      openPorts: 0.2,
      anomalies: 0.1,
      authFailures: 0.0,
      encryptedTraffic: 0.9,
    );
    expect(result['model'], 'local-mlp');
    expect(result['riskProbability'], inInclusiveRange(0, 1));
  });

  test('guardian produces a defensive response for risky indicators', () {
    final ai = ZionAiService();
    final result = ai.guardian(const <String>['credential exposure']);
    expect(result['status'], 'ALERT');
    expect(result['action'], 'BLOCK_AND_AUDIT');
  });
}
