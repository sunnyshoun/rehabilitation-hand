import 'package:flutter/material.dart';
import '../../widgets/common/top_snackbar.dart';

extension ContextExtensions on BuildContext {
  // 快速存取 Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  // 快速存取 MediaQuery
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  
  // 響應式設計輔助方法
  bool get isTablet => screenWidth > 600;
  bool get isCompact => screenHeight < 600;
  
  // 顯示 TopSnackBar 的便利方法
  void showSuccessMessage(String message) {
    showTopSnackBar(
      this,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }
  
  void showErrorMessage(String message) {
    showTopSnackBar(
      this,
      message,
      backgroundColor: Colors.red,
      icon: Icons.error_outline,
    );
  }
  
  void showWarningMessage(String message) {
    showTopSnackBar(
      this,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning_amber_rounded,
    );
  }
  
  void showInfoMessage(String message) {
    showTopSnackBar(
      this,
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info_outline,
    );
  }
  
  // 導航輔助方法
  Future<T?> push<T>(Widget page) {
    return Navigator.push<T>(
      this,
      MaterialPageRoute(builder: (_) => page),
    );
  }
  
  void pop<T>([T? result]) {
    Navigator.pop(this, result);
  }
}