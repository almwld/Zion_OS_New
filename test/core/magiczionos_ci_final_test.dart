import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/magiczionos/magiczionos.dart';

void main() {
  test('MagicZionOS safety defaults are explicit', () {
    const config = MagiczionosConfig();
    expect(config.allowDangerousCommands, isFalse);
    expect(config.autoFallback, isTrue);
  });
}
