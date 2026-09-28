import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceCommand {
  final String phrase;
  final String action;
  const VoiceCommand(this.phrase, this.action);
}

/// Voice navigation layer. It maps speech to safe application actions and does
/// not translate speech into arbitrary shell or attack commands.
class VoiceCommander {
  final SpeechToText _speech;
  bool _isListening = false;
  String _lastText = '';

  VoiceCommander({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  Future<bool> initialize() async {
    try {
      return await _speech.initialize();
    } catch (_) {
      return false;
    }
  }

  Future<String> listen() async {
    if (!_speech.isAvailable) return '';
    _lastText = '';
    _isListening = true;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        _lastText = result.recognizedWords;
        if (result.finalResult) _isListening = false;
      },
    );
    return _lastText;
  }

  String? resolveAction(String text) {
    final value = text.trim().toLowerCase();
    const commands = <VoiceCommand>[
      VoiceCommand('افتح الطرفية', 'open:terminal'),
      VoiceCommand('افتح الملفات', 'open:file_manager'),
      VoiceCommand('افتح المتصفح', 'open:browser'),
      VoiceCommand('افتح الإعدادات', 'open:settings'),
      VoiceCommand('معلومات الجهاز', 'open:system_info'),
      VoiceCommand('معلومات الشبكة', 'open:network_info'),
      VoiceCommand('الرئيسية', 'navigate:home'),
    ];
    for (final command in commands) {
      if (value == command.phrase || value.contains(command.phrase)) return command.action;
    }
    return null;
  }

  bool get isListening => _isListening;
  String get lastText => _lastText;

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
  }
}
