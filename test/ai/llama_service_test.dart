import 'package:flutter_test/flutter_test.dart';

import '../../lib/ai/llama_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generation without a loaded model returns a safe error', () async {
    final service = LlamaService();

    final response = await service.generate('hello');

    expect(response, contains('النموذج المحلي غير محمل'));
  });

  test('empty model path is rejected without invoking the native bridge', () async {
    final service = LlamaService();

    final loaded = await service.loadModel('   ');

    expect(loaded, isFalse);
    expect(service.isLoaded, isFalse);
    expect(service.currentModel, isNull);
  });
}
