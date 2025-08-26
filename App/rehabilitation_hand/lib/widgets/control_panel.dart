import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spp_connection_plugin/spp_connection_plugin.dart';
import '../services/bluetooth_service.dart';
import 'motion_templates_tab.dart';
import 'custom_motion_tab.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasAttemptedAutoConnect = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 自動嘗試連接上次的設備
    _attemptAutoConnect();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _attemptAutoConnect() async {
    if (_hasAttemptedAutoConnect) return;
    _hasAttemptedAutoConnect = true;

    final btService = Provider.of<BluetoothService>(context, listen: false);

    // 如果已經連接或沒有上次連接的設備，直接返回
    if (btService.connected || btService.lastConnectedDevice == null) {
      return;
    }

    // 檢查藍牙是否啟用
    final isEnabled = await btService.isBluetoothEnabled();
    if (!isEnabled) {
      // 不強制開啟藍牙，只是嘗試連接
      return;
    }

    // 檢查權限
    final hasPermissions = await btService.checkPermissions();
    if (!hasPermissions) {
      return;
    }

    // 嘗試重連上次的設備
    await btService.tryReconnectLastDevice();
  }

  Future<void> _showBluetoothDevices() async {
    final btService = Provider.of<BluetoothService>(context, listen: false);

    // 先檢查藍牙是否開啟
    final isEnabled = await btService.isBluetoothEnabled();
    if (!isEnabled) {
      final shouldEnable = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
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
        // 等待藍牙開啟
        await Future.delayed(const Duration(seconds: 2));
      } else {
        return;
      }
    }

    // 檢查權限
    final hasPermissions = await btService.checkPermissions();
    if (!hasPermissions && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('需要藍牙權限才能連接設備')));
      return;
    }

    // 顯示設備列表對話框
    if (mounted) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => const BluetoothDeviceListDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothService>(context);
    final deviceName = btService.getConnectedDeviceName();

    return Column(
      children: [
        // 連線狀態列
        Container(
          color: btService.connected ? Colors.green : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                btService.connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color:
                    btService.connected ? Colors.white : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  btService.connected
                      ? '已連接: ${deviceName ?? "未知設備"}'
                      : '未連接藍牙設備',
                  style: TextStyle(
                    color:
                        btService.connected
                            ? Colors.white
                            : Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 藍牙設備列表按鈕
              IconButton(
                onPressed: _showBluetoothDevices,
                icon: Icon(
                  Icons.bluetooth_searching,
                  color: btService.connected ? Colors.white : Colors.blue,
                  size: 22,
                ),
                tooltip: '選擇藍牙設備',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // 連接/斷開按鈕
              if (btService.connected)
                TextButton.icon(
                  onPressed: () {
                    btService.disconnect();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已斷開連接')));
                  },
                  icon: Icon(Icons.link_off, color: Colors.white, size: 18),
                  label: const Text(
                    '斷開',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _showBluetoothDevices,
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('連接', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Tab標籤
        Container(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: '動作模板'), Tab(text: '自訂動作')],
          ),
        ),
        // Tab內容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [MotionTemplatesTab(), CustomMotionTab()],
          ),
        ),
      ],
    );
  }
}

// 藍牙設備列表對話框（簡化版）
class BluetoothDeviceListDialog extends StatefulWidget {
  const BluetoothDeviceListDialog({super.key});

  @override
  State<BluetoothDeviceListDialog> createState() =>
      _BluetoothDeviceListDialogState();
}

class _BluetoothDeviceListDialogState extends State<BluetoothDeviceListDialog> {
  bool _isConnecting = false;
  String? _connectingDeviceAddress;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    final btService = Provider.of<BluetoothService>(context, listen: false);
    await btService.scanDevices();
  }

  Future<void> _connectToDevice(BluetoothDeviceModel device) async {
    final btService = Provider.of<BluetoothService>(context, listen: false);

    setState(() {
      _isConnecting = true;
      _connectingDeviceAddress = device.address;
    });

    final success = await btService.connectToDevice(device.address);

    if (success && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已連接到 ${device.displayName}')));
    } else {
      setState(() {
        _isConnecting = false;
        _connectingDeviceAddress = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('無法連接到 ${device.displayName}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothService>(context);
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 600 ? 500.0 : screenSize.width * 0.9;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bluetooth, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('選擇藍牙設備'),
          const Spacer(),
          // 已連接標記
          if (btService.connected)
            const Chip(
              label: Text('已連接', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        height: 350,
        child:
            btService.scanning
                ? const Center(child: CircularProgressIndicator())
                : btService.devices.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '未找到已配對的設備',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '請先在系統設定中配對藍牙設備',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  itemCount: btService.devices.length,
                  itemBuilder: (context, index) {
                    final device = btService.devices[index];
                    final isCurrentDevice =
                        btService.connected &&
                        device.address == btService.lastConnectedDevice;
                    final isConnecting =
                        _connectingDeviceAddress == device.address;

                    return Card(
                      color: isCurrentDevice ? Colors.green.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isCurrentDevice ? Colors.green : Colors.blue,
                          radius: 20,
                          child: Icon(
                            isCurrentDevice ? Icons.check : Icons.bluetooth,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          device.displayName,
                          style: TextStyle(
                            fontWeight:
                                isCurrentDevice
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.address,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (isCurrentDevice)
                              const Text(
                                '目前連接的設備',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                        trailing:
                            isConnecting
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : isCurrentDevice
                                ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                                : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap:
                            isCurrentDevice || _isConnecting
                                ? null
                                : () => _connectToDevice(device),
                        enabled: !isCurrentDevice && !_isConnecting,
                      ),
                    );
                  },
                ),
      ),
      actions: [
        TextButton.icon(
          onPressed: btService.scanning || _isConnecting ? null : _scanDevices,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('重新掃描'),
        ),
        TextButton(
          onPressed: _isConnecting ? null : () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    );
  }
}
