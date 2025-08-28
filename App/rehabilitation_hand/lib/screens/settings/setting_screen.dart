import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/services/auth_service.dart';
import 'package:rehabilitation_hand/services/theme_service.dart';
import 'widgets/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showThemeModeDialog(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.palette, color: Colors.blue),
            SizedBox(width: 8),
            Text('選擇主題'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeService.availableThemeModes.map((mode) {
            return Consumer<ThemeService>(
              builder: (context, service, _) {
                final isSelected = service.themeMode == mode;
                return ListTile(
                  leading: Icon(
                    ThemeService.getThemeModeIcon(mode),
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(
                    ThemeService.getThemeModeDisplayName(mode),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  trailing: isSelected 
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                  onTap: () {
                    service.setThemeMode(mode);
                    Navigator.of(context).pop();
                  },
                  selected: isSelected,
                  selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
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
                SettingsTile(
                  icon: Icons.language,
                  title: '語言',
                  trailing: DropdownButton<String>(
                    value: '繁體中文',
                    items: const [
                      DropdownMenuItem(value: '繁體中文', child: Text('繁體中文')),
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (value) {
                      // TODO: 更新語言設定
                    },
                  ),
                ),
                const Divider(height: 1),
                Consumer<ThemeService>(
                  builder: (context, themeService, _) {
                    return SettingsTile(
                      icon: ThemeService.getThemeModeIcon(themeService.themeMode),
                      title: '主題模式',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            themeService.themeModeDisplayName,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
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
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('確認登出'),
                    content: const Text('確定要登出嗎？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('登出'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  auth.logout();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('登出'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}