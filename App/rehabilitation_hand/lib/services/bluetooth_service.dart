import 'package:flutter/foundation.dart';
import 'package:spp_connection_plugin/spp_connection_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';

class BluetoothService extends ChangeNotifier {
  final SppConnectionPlugin _spp = SppConnectionPlugin();
  bool _connected = false;
  String? _lastConnectedDevice;
  List<BluetoothDeviceModel> _devices = [];
  bool _scanning = false;
  String _receivedData = '';

  bool get connected => _connected;
  List<BluetoothDeviceModel> get devices => _devices;
  bool get scanning => _scanning;
  String? get lastConnectedDevice => _lastConnectedDevice;
  String get receivedData => _receivedData;

  BluetoothService() {
    _init();
  }

  void _init() {
    // 監聽連線狀態
    _spp.connectionStateStream.listen((state) {
      _connected = state == BluetoothConnectionState.connected;
      notifyListeners();
    });

    // 監聽接收的數據
    _spp.dataStream.listen((data) {
      _receivedData = String.fromCharCodes(data);
      print('Received: $_receivedData');
      notifyListeners();
    });

    _loadLastDevice();
  }

  Future<void> _loadLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    _lastConnectedDevice = prefs.getString('last_device');
  }

  Future<void> _saveLastDevice(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_device', address);
    _lastConnectedDevice = address;
  }

  Future<bool> checkPermissions() async {
    bool hasPermissions = await _spp.hasPermissions();
    if (!hasPermissions) {
      hasPermissions = await _spp.requestPermissions();
    }
    return hasPermissions;
  }

  Future<bool> isBluetoothEnabled() async {
    return await _spp.isBluetoothEnabled();
  }

  Future<void> enableBluetooth() async {
    await _spp.enableBluetooth();
  }

  Future<void> scanDevices() async {
    _scanning = true;
    notifyListeners();

    try {
      _devices = await _spp.getPairedDevices();
    } catch (e) {
      print('Scan error: $e');
      _devices = [];
    }

    _scanning = false;
    notifyListeners();
  }

  Future<bool> connectToDevice(String address) async {
    try {
      await _spp.connectToDevice(address);
      await _saveLastDevice(address);

      // 等待連線確認
      await Future.delayed(const Duration(milliseconds: 500));

      return _connected;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  Future<bool> tryReconnectLastDevice() async {
    if (_lastConnectedDevice != null) {
      // 先掃描確保設備在列表中
      await scanDevices();

      // 檢查上次的設備是否在配對列表中
      final deviceExists = _devices.any(
        (d) => d.address == _lastConnectedDevice,
      );
      if (deviceExists) {
        return await connectToDevice(_lastConnectedDevice!);
      }
    }
    return false;
  }

  void disconnect() {
    _spp.disconnect();
  }

  Future<void> sendCommand(String command) async {
    if (_connected) {
      try {
        await _spp.sendText(command);
        print('Sent: $command');
      } catch (e) {
        print('Send error: $e');
      }
    }
  }

  Future<void> sendData(Uint8List data) async {
    if (_connected) {
      try {
        await _spp.sendData(data);
      } catch (e) {
        print('Send data error: $e');
      }
    }
  }

  Future<void> sendFingerPosition(FingerPosition position) async {
    final command = position.toCommand();
    await sendCommand(command);
  }

  String? getConnectedDeviceName() {
    if (_connected && _lastConnectedDevice != null) {
      try {
        final device = _devices.firstWhere(
          (d) => d.address == _lastConnectedDevice,
        );
        return device.displayName;
      } catch (e) {
        return _lastConnectedDevice;
      }
    }
    return null;
  }
}
