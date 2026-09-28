import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/core/magiczionos/magiczionos.dart';

void main() {
  test('provider starts with explicit non-success state', () {
    final provider = MagiczionosProvider();
    expect(provider.installing, isFalse);
    expect(provider.statuses, isEmpty);
    expect(provider.error, isNull);
  });
}