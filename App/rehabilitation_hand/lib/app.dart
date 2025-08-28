import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/bluetooth_service.dart';
import 'services/motion_storage_service.dart';
import 'services/theme_service.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'config/themes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BluetoothService()),
        ChangeNotifierProvider(create: (_) => MotionStorageService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: '復健手控制系統',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeService.flutterThemeMode,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
            builder: (context, child) {
              // 更新系統亮度狀態到 ThemeService
              final brightness = MediaQuery.of(context).platformBrightness;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                themeService.updateSystemBrightness(brightness);
              });
              return child!;
            },
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