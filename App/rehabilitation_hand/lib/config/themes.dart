import 'package:flutter/material.dart';
import 'constants.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light, // 明確指定亮度
      useMaterial3: true,
      cardTheme: const CardThemeData(
        elevation: AppConstants.cardElevation,
        margin: EdgeInsets.symmetric(vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 32),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      // 可以在這裡加入 colorScheme 來更好地控制顏色
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark, // 明確指定亮度
      useMaterial3: true,
      // [建議] 將 lightTheme 的主題設定也加入 darkTheme，以保持樣式一致
      cardTheme: const CardThemeData(
        elevation: AppConstants.cardElevation,
        margin: EdgeInsets.symmetric(vertical: 4),
        // 在深色模式下，可以指定不同的顏色
        // color: Colors.grey[800],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 32),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      // 為深色模式定義 colorScheme
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }
}

class AppColors {
  // 狀態顏色
  static const Color extendedColor = Colors.amber;
  static const Color relaxedColor = Colors.green;
  static const Color contractedColor = Colors.red;

  // 藍牙狀態顏色
  static const Color connectedColor = Colors.green;
  static const Color disconnectedColor = Colors.orange;

  // 元件顏色
  static const Color customTemplateColor = Colors.purple;
  static const Color defaultTemplateColor = Colors.blue;

  // 背景顏色 (這些在深色模式下可能需要調整)
  static final Color infoBackground = Colors.blue.shade50;
  static final Color warningBackground = Colors.orange.shade50;
  static final Color successBackground = Colors.green.shade50;
  static final Color errorBackground = Colors.red.shade50;
}
