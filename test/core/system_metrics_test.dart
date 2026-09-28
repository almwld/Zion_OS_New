import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/src/core/services/system_metrics.dart';

void main() {
  test('system metrics values stay within safe bounds', () async {
    final m = await SystemMetrics.read();
    expect(m.cpuPercent, inInclusiveRange(0, 100));
    expect(m.memoryPercent, inInclusiveRange(0, 100));
    expect(m.storagePercent, inInclusiveRange(0, 100));
    expect(m.memoryUsedBytes, greaterThanOrEqualTo(0));
    expect(m.memoryTotalBytes, greaterThanOrEqualTo(0));
  });
}
