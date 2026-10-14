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
      'http://[::1]/',
      'http://[::ffff:192.168.1.1]/',
      'http://[::192.168.1.1]/',
      'http://metadata.google.internal/',
    ]) {
      test('rejects local/private target: $address', () async {
        final result = await tool.execute({'action': 'fetch', 'url': address});
        expect(result.success, isFalse);
        expect(result.error, contains('محلي أو خاص'));
      });
    }
  });

  test('declares only read-only web retrieval as an approval-free network capability', () {
    expect(BrowserTool().supportsReadOnlyWebRetrieval, isTrue);
  });

  test('rejects non-HTTP schemes and embedded URL credentials', () async {
    final tool = BrowserTool();
    final fileUrl = await tool.execute({'action': 'fetch', 'url': 'file:///etc/passwd'});
    final credentials = await tool.execute({'action': 'fetch', 'url': 'https://user:pass@example.com/'});
    final invalidAction = await tool.execute({'action': 'delete'});
    expect(fileUrl.success, isFalse);
    expect(credentials.success, isFalse);
    expect(invalidAction.success, isFalse);
  });
}
