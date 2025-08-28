import 'package:flutter/material.dart';

class AppColors {
  // 暗色模式配色 - 更現代化的深色主題
  static const Color darkBackground = Color(0xFF0F1419); // 更深邃的背景
  static const Color darkSectionBackground = Color(0xFF1A1F28); // 區塊背景
  static const Color darkSection = Color(0xFF242B37); // 卡片容器
  static const Color darkCard = Color(0xFF2E3543); // 卡片元件
  static const Color darkSlider = Color(0xFF3A4252); // 滑桿背景
  static const Color darkPrimary = Color(0xFF60A5FA); // 更柔和的藍色
  static const Color darkDivider = Color(0xFF3A4252); // 分隔線

  // 亮色模式配色 - 更柔和的淺色主題
  static const Color lightBackground = Color(0xFFFAFBFC); // 微灰白背景
  static const Color lightSectionBackground = Color(0xFFF5F7FA); // 區塊背景
  static const Color lightSection = Color(0xFFEDF1F6); // 卡片容器
  static const Color lightCard = Colors.white; // 卡片元件
  static const Color lightSlider = Color(0xFFE1E6ED); // 滑桿背景
  static const Color lightPrimary = Color(0xFF3B82F6); // 更鮮明的藍色
  static const Color lightDivider = Color(0xFFE1E6ED); // 分隔線

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackground
          : lightBackground;

  static Color section(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSection
          : lightSection;

  static Color sectionBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSectionBackground
          : lightSectionBackground;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : lightCard;

  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkPrimary
          : lightPrimary;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkDivider
          : lightDivider;

  static Color slider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSlider
          : lightSlider;

  static Color customTemplateColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors
            .purple
            .shade300 // 深色模式下使用較淺的顏色
        : Colors.purple;
  }

  static Color defaultTemplateColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors
            .blue
            .shade300 // 深色模式下使用較淺的顏色
        : Colors.blue;
  }

  static Color button(BuildContext context, Color baseColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(baseColor, Colors.white, 0.3)!
        : baseColor;
  }

  static Color blueButton(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade600
        : Colors.blue;
  }

  static Color infoText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.blue.shade200
          : Colors.blue.shade700;

  /// warning 文字色
  static Color warningText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.orange.shade200
          : Colors.orange.shade700;

  /// success 文字色
  static Color successText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.green.shade200
          : Colors.green.shade700;

  /// error 文字色
  static Color errorText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.red.shade200
          : Colors.red.shade700;

  //拉桿狀態顏色
  static const Color extendedColor = Colors.amber;
  static const Color relaxedColor = Colors.green;
  static const Color contractedColor = Colors.red;

  // 狀態色可視需求擴充
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFD32F2F);
}

class AppThemes {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.lightPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSection,
      foregroundColor: Colors.black,
      elevation: 1,
    ),
    cardColor: AppColors.lightCard,
    dividerColor: AppColors.lightDivider,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      surface: AppColors.lightBackground,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSection,
      selectedItemColor: AppColors.lightPrimary,
      unselectedItemColor: Colors.grey,
    ),
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.darkPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSection,
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkDivider,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      surface: AppColors.darkBackground,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSection,
      selectedItemColor: AppColors.darkPrimary,
      unselectedItemColor: Colors.grey,
    ),
  );
}
