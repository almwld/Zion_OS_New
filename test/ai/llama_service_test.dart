import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zion/ai/llama_service.dart';

const _channel = MethodChannel('zion.os/ai');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'loadModel':
          throw PlatformException(code: 'NATIVE_LOAD_FAILED');
        case 'freeModel':
          throw PlatformException(code: 'NATIVE_UNLOAD_FAILED');
        case 'isLoaded':
          return false;
        case 'cancelGeneration':
          return true;
        case 'discoverModels':
          return <dynamic>[];
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('native load failure is returned without throwing into the UI', () async {
    final service = LlamaService();

    expect(await service.loadModel('/models/test.gguf'), isFalse);
    expect(service.isLoaded, isFalse);
    expect(service.currentModel, isNull);
  });

  test('native unload failure does not break teardown', () async {
    final service = LlamaService();

    await expectLater(service.unloadModel(), completes);
    expect(service.isLoaded, isFalse);
    expect(service.currentModel, isNull);
  });

  test('generation cancellation is exposed without native model loading', () async {
    final service = LlamaService();

    expect(await service.cancelGeneration(), isTrue);
  });

  test('generation reports unloaded model as a normal result', () async {
    final service = LlamaService();

    expect(await service.generate('hello'), contains('غير محمل'));
  });
}
