import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService extends ChangeNotifier {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  SoundService() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await SharedPreferences.getInstance().then((p) => p.setBool('sound_enabled', _soundEnabled));
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    await SharedPreferences.getInstance().then((p) => p.setBool('vibration_enabled', _vibrationEnabled));
    notifyListeners();
  }
}
