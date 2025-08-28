import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/themes.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'services/bluetooth_service.dart';
import 'services/motion_storage_service.dart';
import 'services/language_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BluetoothService()),
        ChangeNotifierProvider(create: (_) => MotionStorageService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'Rehabilitation Hand',
            theme: AppThemes.light,
            darkTheme: AppThemes.dark,
            themeMode: themeService.flutterThemeMode,
            builder: (context, child) {
              // 系統亮度同步
              final brightness = MediaQuery.of(context).platformBrightness;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                themeService.updateSystemBrightness(brightness);
              });
              return child!;
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}