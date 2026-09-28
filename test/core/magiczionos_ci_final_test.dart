import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/magiczionos/magiczionos.dart';

void main() {
  test('final MagicZionOS contract has no implicit dangerous-command enablement', () {
    const config = MagiczionosConfig();
    expect(config.allowDangerousCommands, isFalse);
    expect(config.autoFallback, isTrue);
    expect(StrategyStatus.values, contains(StrategyStatus.available));
    expect(StrategyStatus.values, contains(StrategyStatus.notConfigured));
  });
}
