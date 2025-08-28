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
        color: Colors.grey.shade700, // 深色模式下的卡片顏色，比背景更深
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
        surface: Colors.grey[850],
        onSurface: Colors.grey[100],
        surfaceContainerHighest: Colors.grey[800], // 用於對話框等
        surfaceContainer: Colors.grey[850], // 用於卡片等
      ),
      // 深色模式下的 AppBar 主題
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900], // 更深的背景色
        foregroundColor: Colors.white,
        elevation: 2,
        surfaceTintColor: Colors.transparent, // 移除 Material 3 的表面著色
      ),
      // 深色模式下的底部導航欄
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[850],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[400],
      ),
      // 深色模式下的對話框主題
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.grey.shade700, // 對話框背景使用較深的顏色
        surfaceTintColor: Colors.transparent,
      ),
      // 深色模式下的底部彈窗主題
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.grey.shade700, // 底部彈窗背景使用較深的顏色
        surfaceTintColor: Colors.transparent,
      ),
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

  // 元件顏色 - 根據主題調整
  static Color customTemplateColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.purple.shade300 // 深色模式下使用較淺的顏色
        : Colors.purple;
  }

  static Color defaultTemplateColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade300 // 深色模式下使用較淺的顏色
        : Colors.blue;
  }

  // 按鈕顏色 - 根據主題調整
  static Color getButtonColor(BuildContext context, Color baseColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(baseColor, Colors.white, 0.3)! // 深色模式下混合白色使其變淺
        : baseColor;
  }

  // 專門的藍色按鈕顏色 - 深色模式下使用較暗的藍色
  static Color getBlueButtonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade600 // 深色模式下使用較暗的藍色
        : Colors.blue;
  }

  // 手指滑桿背景顏色
  static Color getSliderBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700 // 深色模式下使用 700（前景元件）
        : Colors.grey.shade300;
  }

  // Section 背景顏色 - 中等層次
  static Color getSectionBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800 // 深色模式下使用 800（中等背景）
        : Colors.grey.shade100; // 亮色模式下使用淺灰色
  }

  // 卡片和元件的背景顏色 - 最淺的前景
  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700 // 深色模式下使用 700（最淺前景）
        : Colors.white; // 亮色模式下保持白色
  }

  // APP 背景顏色 - 最深的背景
  static Color getAppBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900 // 深色模式下使用 900（最深背景）
        : Colors.white; // 亮色模式下保持白色
  }

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

  // 已廢棄的方法 - 請使用上面的新方法
  // getIndicatorBackground -> getSectionBackground  
  // getPlaylistBackground -> getSectionBackground
  // getLibraryBackground -> getSectionBackground

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

  // 保持向後兼容的靜態顏色
  static const Color customTemplateColorStatic = Colors.purple;
  static const Color defaultTemplateColorStatic = Colors.blue;
}