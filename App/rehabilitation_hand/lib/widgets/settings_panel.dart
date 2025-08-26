import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

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
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('通知設定'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // TODO: 更新通知設定
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('語言'),
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
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('深色模式'),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      // TODO: 切換深色模式
                    },
                  ),
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
                  builder:
                      (context) => AlertDialog(
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
