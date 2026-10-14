import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/agent/tools/browser_tool.dart';

void main() {
  group('BrowserTool address validation', () {
    final tool = BrowserTool();

    for (final address in <String>[
      'http://localhost/',
      'http://127.0.0.1/',
      'http://10.0.0.8/',
      'http://192.168.1.1/',
      'http://169.254.169.254/latest/meta-data/',
    ]) {
      test('rejects local/private target: $address', () async {
        final result = await tool.execute({'action': 'fetch', 'url': address});
        expect(result.success, isFalse);
        expect(result.error, contains('محلي أو خاص'));
      });
    }
  });
}
