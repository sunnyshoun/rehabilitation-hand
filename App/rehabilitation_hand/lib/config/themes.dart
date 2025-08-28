import 'package:flutter/material.dart';
import 'constants.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
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
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      // 自定義過渡動畫時間
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: AppConstants.cardElevation,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.grey[850], // 深色模式下的卡片顏色
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
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        fillColor: Colors.grey[800],
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ).copyWith(
        surface: Colors.grey[900],
        onSurface: Colors.grey[100],
        background: Colors.black,
        onBackground: Colors.grey[100],
      ),
      // 深色模式下的 AppBar 主題
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      // 深色模式下的底部導航欄
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[850],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[400],
      ),
      // 自定義過渡動畫時間
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
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

  // 背景顏色 (亮色模式)
  static final Color lightInfoBackground = Colors.blue.shade50;
  static final Color lightWarningBackground = Colors.orange.shade50;
  static final Color lightSuccessBackground = Colors.green.shade50;
  static final Color lightErrorBackground = Colors.red.shade50;

  // 背景顏色 (深色模式)
  static final Color darkInfoBackground = Colors.blue.shade900.withOpacity(0.3);
  static final Color darkWarningBackground = Colors.orange.shade900.withOpacity(0.3);
  static final Color darkSuccessBackground = Colors.green.shade900.withOpacity(0.3);
  static final Color darkErrorBackground = Colors.red.shade900.withOpacity(0.3);

  // 根據主題取得背景顏色的方法
  static Color getInfoBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkInfoBackground
        : lightInfoBackground;
  }

  static Color getWarningBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkWarningBackground
        : lightWarningBackground;
  }

  static Color getSuccessBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSuccessBackground
        : lightSuccessBackground;
  }

  static Color getErrorBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkErrorBackground
        : lightErrorBackground;
  }

  // 文字顏色 (根據背景調整)
  static Color getInfoTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade200
        : Colors.blue.shade700;
  }

  static Color getWarningTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.orange.shade200
        : Colors.orange.shade700;
  }

  static Color getSuccessTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.green.shade200
        : Colors.green.shade700;
  }

  static Color getErrorTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.red.shade200
        : Colors.red.shade700;
  }
}