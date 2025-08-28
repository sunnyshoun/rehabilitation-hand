import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/services/bluetooth_service.dart';
import 'package:rehabilitation_hand/widgets/bluetooth/bluetooth_connection_dialog.dart';
import 'package:rehabilitation_hand/screens/control/control_screen.dart';
import 'package:rehabilitation_hand/screens/settings/setting_screen.dart';
import 'widgets/home_panel.dart';

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

  Future<void> _showBluetoothDevices() async {
    final btService = Provider.of<BluetoothService>(context, listen: false);

    final isEnabled = await btService.isBluetoothEnabled();
    if (!isEnabled) {
      final shouldEnable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bluetooth_disabled, color: Colors.orange),
              SizedBox(width: 8),
              Text('藍牙未開啟'),
            ],
          ),
          content: const Text('需要開啟藍牙才能連接設備'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.bluetooth),
              label: const Text('開啟藍牙'),
            ),
          ],
        ),
      );

      if (shouldEnable == true) {
        await btService.enableBluetooth();
        await Future.delayed(const Duration(seconds: 2));
      } else {
        return;
      }
    }

    final hasPermissions = await btService.checkPermissions();
    if (!hasPermissions && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要藍牙權限才能連接設備')),
      );
      return;
    }

    if (mounted) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => const BluetoothConnectionDialog(),
      );
    }
  }

  void _showDisconnectDialog() {
    final btService = Provider.of<BluetoothService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認斷開連接'),
        content: Text(
          '確定要斷開與 ${btService.getConnectedDeviceName() ?? "設備"} 的連接嗎？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              btService.disconnect();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已斷開連接')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('斷開'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_selectedIndex == 1)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildBluetoothButton(btService),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomePanel(),
          ControlScreen(),
          SettingsScreen(),
        ],
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

  Widget _buildBluetoothButton(BluetoothService btService) {
    if (btService.connected) {
      return TextButton.icon(
        onPressed: _showDisconnectDialog,
        icon: const Icon(
          Icons.bluetooth_connected,
          color: Colors.white,
          size: 18,
        ),
        label: Text(
          btService.getConnectedDeviceName() ?? '已連接',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    } else {
      return TextButton.icon(
        onPressed: _showBluetoothDevices,
        icon: const Icon(
          Icons.bluetooth_disabled,
          color: Colors.white,
          size: 18,
        ),
        label: const Text(
          '未連接',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
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