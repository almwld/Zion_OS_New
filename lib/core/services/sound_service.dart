import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight device feedback service. It uses Flutter's real platform
/// feedback APIs and never pretends that an audio asset was played.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_effects') ?? true;
  }

  Future<void> playClick() async {
    if (!_soundEnabled) return;
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playSuccess() async {
    if (!_soundEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> playError() async {
    if (!_soundEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_effects', enabled);
  }
}
