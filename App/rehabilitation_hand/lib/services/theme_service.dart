import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  AppThemeMode _themeMode = AppThemeMode.system;
  Brightness? _systemBrightness;

  AppThemeMode get themeMode => _themeMode;
  Brightness? get systemBrightness => _systemBrightness;

  /// 取得當前應該使用的 Flutter ThemeMode
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

  /// 取得主題模式的顯示名稱
  String get themeModeDisplayName {
    switch (_themeMode) {
      case AppThemeMode.system:
        return '根據系統';
      case AppThemeMode.light:
        return '亮色模式';
      case AppThemeMode.dark:
        return '深色模式';
    }
  }

  ThemeService() {
    _loadThemeMode();
  }

  /// 從本地儲存載入主題設定
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);

      if (savedMode != null) {
        _themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedMode,
          orElse: () => AppThemeMode.system,
        );
      }

      notifyListeners();
    } catch (e) {
      print('載入主題設定時發生錯誤: $e');
    }
  }

  /// 儲存主題設定到本地
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeMode.toString());
    } catch (e) {
      print('儲存主題設定時發生錯誤: $e');
    }
  }

  /// 更新系統亮度（由 MaterialApp 呼叫）
  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness != brightness) {
      _systemBrightness = brightness;
      // 如果當前是根據系統模式，需要通知更新
      if (_themeMode == AppThemeMode.system) {
        notifyListeners();
      }
    }
  }

  /// 設定主題模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemeMode();
      notifyListeners();
    }
  }

  /// 切換到下一個主題模式（用於快速切換）
  Future<void> toggleThemeMode() async {
    final modes = AppThemeMode.values;
    final currentIndex = modes.indexOf(_themeMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    await setThemeMode(modes[nextIndex]);
  }

  /// 取得所有可用的主題模式選項
  static List<AppThemeMode> get availableThemeModes => AppThemeMode.values;

  /// 取得主題模式的顯示名稱（靜態方法）
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

  /// 取得主題模式的圖示
  static IconData getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.brightness_high;
      case AppThemeMode.dark:
        return Icons.brightness_low;
    }
  }
}
