import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  AppThemeMode _themeMode = AppThemeMode.system;
  Brightness? _systemBrightness;

  AppThemeMode get themeMode => _themeMode;
  Brightness? get systemBrightness => _systemBrightness;

  ThemeService() {
    _loadThemeMode();
  }

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModeKey);
    _themeMode = AppThemeMode.values.firstWhere(
      (e) => e.toString() == saved,
      orElse: () => AppThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeMode.toString());
  }

  void updateSystemBrightness(Brightness brightness) {
    _systemBrightness = brightness;
    if (_themeMode == AppThemeMode.system) notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemeMode();
      notifyListeners();
    }
  }

  Future<void> toggleThemeMode() async {
    final idx =
        (AppThemeMode.values.indexOf(_themeMode) + 1) %
        AppThemeMode.values.length;
    await setThemeMode(AppThemeMode.values[idx]);
  }

  static List<AppThemeMode> get availableThemeModes => AppThemeMode.values;
  static String getThemeModeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return '根據系統';
      case AppThemeMode.light:
        return '亮色模式';
      case AppThemeMode.dark:
        return '深色模式';
    }
  }

  static IconData getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.brightness_high;
      case AppThemeMode.dark:
        return Icons.brightness_2;
    }
  }
}
