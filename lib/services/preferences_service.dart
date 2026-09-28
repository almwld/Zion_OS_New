import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesService extends ChangeNotifier {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // إعدادات الثيم
  String _themeColor = 'Cyan';
  bool _isDarkMode = true;
  final List<String> _availableColors = ['Cyan', 'Blue', 'Purple', 'Green', 'Orange', 'Pink'];

  // إعدادات اللغة
  String _languageCode = 'ar';
  bool _isRTL = true;

  // إعدادات الخط
  double _fontScale = 1.0;
  double _minFontScale = 0.8;
  double _maxFontScale = 1.5;

  // إعدادات الأيقونات
  double _iconSize = 55.0;
  double _minIconSize = 30.0;
  double _maxIconSize = 80.0;
  bool _showAppNames = true;
  int _iconsPerRow = 4;

  // إعدادات الخلفية
  String _wallpaperPath = 'assets/images/default_wallpaper.jpg';
  double _wallpaperBlur = 0.0;
  bool _useCustomWallpaper = false;

  // إعدادات الأمان
  bool _useBiometric = false;
  int _pinLength = 4;

  // إعدادات النوافذ
  double _radarPositionX = 0.0;
  double _radarPositionY = 0.0;
  bool _radarVisible = true;

  // Getters
  String get themeColor => _themeColor;
  bool get isDarkMode => _isDarkMode;
  List<String> get availableColors => _availableColors;
  String get languageCode => _languageCode;
  bool get isRTL => _isRTL;
  double get fontScale => _fontScale;
  double get minFontScale => _minFontScale;
  double get maxFontScale => _maxFontScale;
  double get iconSize => _iconSize;
  double get minIconSize => _minIconSize;
  double get maxIconSize => _maxIconSize;
  bool get showAppNames => _showAppNames;
  int get iconsPerRow => _iconsPerRow;
  String get wallpaperPath => _wallpaperPath;
  double get wallpaperBlur => _wallpaperBlur;
  bool get useCustomWallpaper => _useCustomWallpaper;
  bool get useBiometric => _useBiometric;
  int get pinLength => _pinLength;
  double get radarPositionX => _radarPositionX;
  double get radarPositionY => _radarPositionY;
  bool get radarVisible => _radarVisible;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    _themeColor = _prefs.getString('theme_color') ?? 'Cyan';
    _isDarkMode = _prefs.getBool('is_dark_mode') ?? true;
    _languageCode = _prefs.getString('language_code') ?? 'ar';
    _isRTL = _languageCode == 'ar';
    _fontScale = _prefs.getDouble('font_scale') ?? 1.0;
    _iconSize = _prefs.getDouble('icon_size') ?? 55.0;
    _showAppNames = _prefs.getBool('show_app_names') ?? true;
    _iconsPerRow = _prefs.getInt('icons_per_row') ?? 4;
    _wallpaperPath = _prefs.getString('wallpaper_path') ?? 'assets/images/default_wallpaper.jpg';
    _wallpaperBlur = _prefs.getDouble('wallpaper_blur') ?? 0.0;
    _useCustomWallpaper = _prefs.getBool('use_custom_wallpaper') ?? false;
    _useBiometric = _prefs.getBool('use_biometric') ?? false;
    _pinLength = _prefs.getInt('pin_length') ?? 4;
    _radarPositionX = _prefs.getDouble('radar_position_x') ?? 0.0;
    _radarPositionY = _prefs.getDouble('radar_position_y') ?? 0.0;
    _radarVisible = _prefs.getBool('radar_visible') ?? true;
    
    notifyListeners();
  }

  // Theme Methods
  Future<void> setThemeColor(String color) async {
    _themeColor = color;
    await _prefs.setString('theme_color', color);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _prefs.setBool('is_dark_mode', isDark);
    notifyListeners();
  }

  // Language Methods
  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    _isRTL = code == 'ar';
    await _prefs.setString('language_code', code);
    notifyListeners();
  }

  // Font Methods
  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(_minFontScale, _maxFontScale);
    await _prefs.setDouble('font_scale', _fontScale);
    notifyListeners();
  }

  // Icon Methods
  Future<void> setIconSize(double size) async {
    _iconSize = size.clamp(_minIconSize, _maxIconSize);
    await _prefs.setDouble('icon_size', _iconSize);
    notifyListeners();
  }

  Future<void> setShowAppNames(bool show) async {
    _showAppNames = show;
    await _prefs.setBool('show_app_names', show);
    notifyListeners();
  }

  Future<void> setIconsPerRow(int count) async {
    _iconsPerRow = count.clamp(3, 5);
    await _prefs.setInt('icons_per_row', _iconsPerRow);
    notifyListeners();
  }

  // Wallpaper Methods
  Future<void> setWallpaper(String path, {bool isCustom = true}) async {
    _wallpaperPath = path;
    _useCustomWallpaper = isCustom;
    await _prefs.setString('wallpaper_path', path);
    await _prefs.setBool('use_custom_wallpaper', isCustom);
    notifyListeners();
  }

  Future<void> setWallpaperBlur(double blur) async {
    _wallpaperBlur = blur.clamp(0.0, 20.0);
    await _prefs.setDouble('wallpaper_blur', _wallpaperBlur);
    notifyListeners();
  }

  Future<void> resetToDefaultWallpaper() async {
    _wallpaperPath = 'assets/images/default_wallpaper.jpg';
    _useCustomWallpaper = false;
    await _prefs.setString('wallpaper_path', _wallpaperPath);
    await _prefs.setBool('use_custom_wallpaper', false);
    notifyListeners();
  }

  // Security Methods
  Future<void> setUseBiometric(bool use) async {
    _useBiometric = use;
    await _prefs.setBool('use_biometric', use);
    notifyListeners();
  }

  Future<void> setPinLength(int length) async {
    _pinLength = length.clamp(4, 6);
    await _prefs.setInt('pin_length', _pinLength);
    notifyListeners();
  }

  Future<void> changePin(String oldPin, String newPin) async {
    String? currentPin = await _secureStorage.read(key: 'user_pin');
    if (currentPin == oldPin && newPin.length >= _pinLength) {
      await _secureStorage.write(key: 'user_pin', value: newPin);
      return;
    }
    throw Exception('PIN غير صحيح أو قصير جداً');
  }

  Future<String?> getCurrentPin() async {
    return await _secureStorage.read(key: 'user_pin');
  }

  Future<bool> verifyPin(String pin) async {
    String? savedPin = await _secureStorage.read(key: 'user_pin');
    return savedPin == pin;
  }

  // Radar Methods
  Future<void> setRadarPosition(double x, double y) async {
    _radarPositionX = x;
    _radarPositionY = y;
    await _prefs.setDouble('radar_position_x', x);
    await _prefs.setDouble('radar_position_y', y);
    notifyListeners();
  }

  Future<void> setRadarVisible(bool visible) async {
    _radarVisible = visible;
    await _prefs.setBool('radar_visible', visible);
    notifyListeners();
  }

  // Reset All Settings
  Future<void> resetAllSettings() async {
    await _prefs.clear();
    await _loadAllSettings();
    await _secureStorage.write(key: 'user_pin', value: '1234');
    notifyListeners();
  }
}
