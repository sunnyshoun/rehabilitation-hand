import 'package:flutter/material.dart';

class AppColors {
  // 層級：最深背景 → 中層區塊 → 卡片/元件 → 前景/強調色
  static const Color darkBackground = Color(0xFF121212); // 最深
  static const Color darkSection = Color(0xFF21252A); // 中間
  static const Color darkCard = Color(0xFF2D3137); // 最淺前景
  static const Color darkPrimary = Color(0xFF448AFF);
  static const Color darkDivider = Color(0xFF33373D);

  static const Color lightBackground = Colors.white;
  static const Color lightSection = Color(0xFFF4F6F8);
  static const Color lightCard = Colors.white;
  static const Color lightPrimary = Colors.blue;
  static const Color lightDivider = Color(0xFFE0E0E0);

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackground
          : lightBackground;

  static Color section(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSection
          : lightSection;

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
