import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/magiczionos/magiczionos.dart';

void main() {
  test('real command contract is explicit', () {
    const config = MagiczionosConfig();
    expect(config.allowDangerousCommands, isFalse);
    expect(config.autoFallback, isTrue);
    expect(StrategyStatus.values, contains(StrategyStatus.available));
    expect(StrategyStatus.values, contains(StrategyStatus.notConfigured));
  });
}
