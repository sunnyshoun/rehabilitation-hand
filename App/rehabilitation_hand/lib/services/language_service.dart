import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { traditionalChinese, english, simplifiedChinese, japanese }

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  AppLanguage _currentLanguage = AppLanguage.traditionalChinese;

  AppLanguage get currentLanguage => _currentLanguage;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    _currentLanguage = AppLanguage.values.firstWhere(
      (e) => e.toString() == saved,
      orElse: () => AppLanguage.traditionalChinese,
    );
    notifyListeners();
  }

  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _currentLanguage.toString());
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      await _saveLanguage();
      notifyListeners();
    }
  }

  static List<AppLanguage> get availableLanguages => AppLanguage.values;

  static String getLanguageDisplayName(AppLanguage language) {
    switch (language) {
      case AppLanguage.traditionalChinese:
        return '繁體中文';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.simplifiedChinese:
        return '简体中文';
      case AppLanguage.japanese:
        return '日本語';
    }
  }

  static IconData getLanguageIcon(AppLanguage language) {
    return Icons.language;
  }

  static String getLanguageCode(AppLanguage language) {
    switch (language) {
      case AppLanguage.traditionalChinese:
        return 'zh-TW';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.simplifiedChinese:
        return 'zh-CN';
      case AppLanguage.japanese:
        return 'ja';
    }
  }
}
