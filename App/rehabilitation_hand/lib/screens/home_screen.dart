import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/bluetooth_service.dart';
import '../widgets/home_panel.dart';
import '../widgets/control_panel.dart';
import '../widgets/settings_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final btService = Provider.of<BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 藍牙狀態指示器（只在控制頁面顯示）
          if (_selectedIndex == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                avatar: Icon(
                  btService.connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  btService.connected ? '已連接' : '未連接',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor:
                    btService.connected ? Colors.green : Colors.orange,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '歡迎, ${auth.currentUser?.username ?? 'User'}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [HomePanel(), ControlPanel(), SettingsPanel()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(icon: Icon(Icons.pan_tool), label: '復健手控制'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return '首頁';
      case 1:
        return '復健手控制';
      case 2:
        return '設定';
      default:
        return '復健手控制系統';
    }
  }
}
