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

  test('a new service instance reconnects to the process-wide loaded model', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      if (call.method == 'sessionState') {
        return <String, Object?>{
          'loaded': true,
          'modelPath': '/models/qwen.gguf',
          'modelStatus': 'LOADED',
          'generationStatus': 'IDLE',
        };
      }
      return null;
    });

    // Simulates a feature opening after Offline AI loaded the native singleton
    // through a different LlamaService instance.
    final service = LlamaService();

    expect(service.isLoaded, isFalse);
    expect(await service.refreshLoadedState(), isTrue);
    expect(service.isLoaded, isTrue);
    expect(service.currentModel, '/models/qwen.gguf');
  });

  test('generation cancellation is exposed without native model loading', () async {
    final service = LlamaService();

    expect(await service.cancelGeneration(), isTrue);
  });

  test('generation reports unloaded model as a normal result', () async {
    final service = LlamaService();

    expect(await service.generate('hello'), contains('غير محمل'));
  });

  test('LlamaService constructors share process-wide readiness state', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      if (call.method == 'sessionState') {
        return <String, Object?>{
          'loaded': true,
          'modelPath': '/models/shared-qwen.gguf',
          'modelStatus': 'LOADED',
          'generationStatus': 'IDLE',
        };
      }
      return null;
    });

    final loader = LlamaService();
    final terminalFacade = LlamaService();
    expect(await loader.refreshLoadedState(), isTrue);
    expect(terminalFacade.isLoaded, isTrue);
    expect(terminalFacade.currentModel, '/models/shared-qwen.gguf');
  });

  test('loading the already-active GGUF reuses the native session', () async {
    var loadCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'sessionState':
          return <String, Object?>{
            'loaded': true,
            'modelPath': '/models/shared-qwen.gguf',
            'modelStatus': 'LOADED',
            'generationStatus': 'IDLE',
          };
        case 'loadModel':
          loadCalls++;
          return true;
        default:
          return null;
      }
    });

    final service = LlamaService();
    expect(await service.loadModel('/models/shared-qwen.gguf'), isTrue);
    expect(loadCalls, 0,
        reason: 'Navigating between AI surfaces must not reload the active GGUF.');
    expect(service.currentModel, '/models/shared-qwen.gguf');
  });

}
