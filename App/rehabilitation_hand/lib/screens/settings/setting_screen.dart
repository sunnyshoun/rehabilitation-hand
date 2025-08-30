import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/services/auth_service.dart';
import 'package:rehabilitation_hand/services/theme_service.dart';
import 'package:rehabilitation_hand/services/language_service.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showThemeModeDialog(BuildContext context) {
    Provider.of<ThemeService>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.palette, color: Colors.blue),
                SizedBox(width: 8),
                Text('選擇主題'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ThemeService.availableThemeModes.map((mode) {
                    return Consumer<ThemeService>(
                      builder: (context, service, _) {
                        final isSelected = service.themeMode == mode;
                        return ListTile(
                          leading: Icon(
                            ThemeService.getThemeModeIcon(mode),
                            color:
                                isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                          ),
                          title: Text(
                            ThemeService.getThemeModeDisplayName(mode),
                            style: TextStyle(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : null,
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check,
                                    color: Theme.of(context).primaryColor,
                                  )
                                  : null,
                          onTap: () {
                            service.setThemeMode(mode);
                            Navigator.of(context).pop();
                          },
                          selected: isSelected,
                          selectedTileColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
            actions: [
              CommonButton(
                label: '完成',
                onPressed: () => Navigator.of(context).pop(),
                type: CommonButtonType.solid,
                shape: CommonButtonShape.capsule,
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
              ),
            ],
          ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    Provider.of<LanguageService>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.language, color: Colors.blue),
                SizedBox(width: 8),
                Text('選擇語言'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  LanguageService.availableLanguages.map((language) {
                    return Consumer<LanguageService>(
                      builder: (context, service, _) {
                        final isSelected = service.currentLanguage == language;
                        return ListTile(
                          leading: Icon(
                            LanguageService.getLanguageIcon(language),
                            color:
                                isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                          ),
                          title: Text(
                            LanguageService.getLanguageDisplayName(language),
                            style: TextStyle(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : null,
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check,
                                    color: Theme.of(context).primaryColor,
                                  )
                                  : null,
                          onTap: () {
                            service.setLanguage(language);
                            Navigator.of(context).pop();
                          },
                          selected: isSelected,
                          selectedTileColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
            actions: [
              CommonButton(
                label: '完成',
                onPressed: () => Navigator.of(context).pop(),
                type: CommonButtonType.solid,
                shape: CommonButtonShape.capsule,
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('個人資料'),
              subtitle: Text(
                '${auth.currentUser?.username} - ${auth.currentUser?.email}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: 編輯個人資料
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.notifications,
                  title: '通知設定',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // TODO: 更新通知設定
                    },
                  ),
                ),
                const Divider(height: 1),
                Consumer<LanguageService>(
                  builder: (context, languageService, _) {
                    return SettingsTile(
                      icon: Icons.language,
                      title: '語言',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            LanguageService.getLanguageDisplayName(
                              languageService.currentLanguage,
                            ),
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () => _showLanguageDialog(context),
                    );
                  },
                ),
                const Divider(height: 1),
                Consumer<ThemeService>(
                  builder: (context, themeService, _) {
                    return SettingsTile(
                      icon: ThemeService.getThemeModeIcon(
                        themeService.themeMode,
                      ),
                      title: '主題模式',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ThemeService.getThemeModeDisplayName(
                              themeService.themeMode,
                            ),
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () => _showThemeModeDialog(context),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('關於'),
              subtitle: const Text('版本 1.0.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: '復健手控制系統',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 Rehab Hand Control System',
                );
              },
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: CommonButton(
              label: '登出',
              icon: Icons.logout,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('確認登出'),
                        content: const Text('確定要登出嗎？'),
                        actions: [
                          CommonButton(
                            label: '取消',
                            onPressed: () => Navigator.pop(context, false),
                            type: CommonButtonType.transparent,
                            shape: CommonButtonShape.capsule,
                            textColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                          ),
                          CommonButton(
                            label: '登出',
                            onPressed: () => Navigator.pop(context, true),
                            type: CommonButtonType.solid,
                            shape: CommonButtonShape.capsule,
                            color: AppColors.button(context, Colors.red),
                            textColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                          ),
                        ],
                      ),
                );

                if (!context.mounted) return; // Guard after dialog
                if (confirm == true) {
                  auth.logout();
                }
              },
              type: CommonButtonType.solid,
              shape: CommonButtonShape.capsule,
              color: AppColors.button(context, Colors.red),
              textColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
