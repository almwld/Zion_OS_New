import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();
  
  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_effects') ?? true;
  }
  
  Future<void> playClick() async {
    if (!_soundEnabled) return;
    // Simulate click sound (can be replaced with actual audio file)
  }
  
  Future<void> playSuccess() async {
    if (!_soundEnabled) return;
    // Simulate success sound
  }
  
  Future<void> playError() async {
    if (!_soundEnabled) return;
    // Simulate error sound
  }
  
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) => p.setBool('sound_effects', enabled));
  }
}
