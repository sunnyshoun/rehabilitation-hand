import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spp_connection_plugin/spp_connection_plugin.dart';
import 'package:rehabilitation_hand/services/bluetooth_service.dart';

class BluetoothConnectionDialog extends StatefulWidget {
  const BluetoothConnectionDialog({super.key});

  @override
  State<BluetoothConnectionDialog> createState() => _BluetoothConnectionDialogState();
}

class _BluetoothConnectionDialogState extends State<BluetoothConnectionDialog> {
  bool _isConnecting = false;
  String _statusMessage = '正在初始化...';
  BluetoothDeviceModel? _connectingDevice;

  @override
  void initState() {
    super.initState();
    _initializeAndConnect();
  }

  Future<void> _initializeAndConnect() async {
    final btService = Provider.of<BluetoothService>(context, listen: false);
    
    // 檢查權限
    setState(() {
      _statusMessage = '正在檢查權限...';
    });
    
    final hasPermissions = await btService.checkPermissions();
    if (!hasPermissions && mounted) {
      setState(() {
        _statusMessage = '藍牙權限被拒絕';
      });
      Navigator.of(context).pop(false);
      return;
    }

    // 嘗試連接上次的設備
    if (btService.lastConnectedDevice != null) {
      setState(() {
        _isConnecting = true;
        _statusMessage = '正在嘗試連接上次的設備...';
      });

      final reconnected = await btService.tryReconnectLastDevice();
      if (reconnected && mounted) {
        Navigator.of(context).pop(true);
        return;
      }
    }

    // 掃描設備
    setState(() {
      _statusMessage = '正在掃描已配對的設備...';
    });
    
    await btService.scanDevices();
    
    setState(() {
      _isConnecting = false;
      _statusMessage = btService.devices.isEmpty 
        ? '未找到已配對的設備' 
        : '請選擇要連接的設備';
    });
  }

  Future<void> _connect(BluetoothDeviceModel device) async {
    final btService = Provider.of<BluetoothService>(context, listen: false);
    
    setState(() {
      _isConnecting = true;
      _connectingDevice = device;
      _statusMessage = '正在連接 ${device.displayName}...';
    });

    final success = await btService.connectToDevice(device.address);
    
    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isConnecting = false;
        _connectingDevice = null;
        _statusMessage = '連接失敗，請重試';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法連接到 ${device.displayName}')),
        );
      }
    }
  }

  Future<void> _rescan() async {
    final btService = Provider.of<BluetoothService>(context, listen: false);
    
    setState(() {
      _statusMessage = '正在重新掃描...';
    });
    
    await btService.scanDevices();
    
    setState(() {
      _statusMessage = btService.devices.isEmpty 
        ? '未找到已配對的設備' 
        : '請選擇要連接的設備';
    });
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
          const Text('藍牙設備連接'),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        height: 400,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_isConnecting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (btService.scanning)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (btService.devices.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '未找到已配對的設備',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '請先在系統設定中配對藍牙設備',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: btService.devices.length,
                  itemBuilder: (context, index) {
                    final device = btService.devices[index];
                    final isConnecting = _connectingDevice == device;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: device.bonded 
                            ? Colors.blue 
                            : Colors.grey,
                          child: const Icon(
                            Icons.bluetooth,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          device.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.address,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (device.bonded)
                              const Text(
                                '已配對',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                        trailing: isConnecting 
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _isConnecting ? null : () => _connect(device),
                        enabled: !_isConnecting,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _isConnecting ? null : _rescan,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('重新掃描'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
      ],
    );
  }
}