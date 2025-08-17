// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  // optional logging
  FlutterBluePlus.setLogLevel(LogLevel.info);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rehabilitation_hand',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});
  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  StreamSubscription<List<ScanResult>>? _scanSub;
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  final TextEditingController _cmdController = TextEditingController();
  String _selectedBaud = '9600';
  bool _scanning = false;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _cmdController.dispose();
    super.dispose();
  }

  Future<void> startScan({int timeoutSeconds = 5}) async {
    _scanSub?.cancel();
    setState(() {
      _scanResults = [];
      _scanning = true;
    });

    // listen to scan results (returns List<ScanResult>)
    _scanSub = FlutterBluePlus.scanResults.listen(
      (results) {
        setState(() => _scanResults = results);
      },
      onError: (e) {
        debugPrint('scan error: $e');
      },
    );

    // start scan (static API)
    await FlutterBluePlus.startScan(timeout: Duration(seconds: timeoutSeconds));
    setState(() => _scanning = false);
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    setState(() => _scanning = false);
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_connectedDevice != null) await disconnectDevice();

    setState(() => _connecting = true);
    // connect (device API)
    try {
      await device.connect();
    } catch (e) {
      // sometimes throws if already connected; ignore
      debugPrint('connect error: $e');
    }

    // listen connection state
    final sub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        setState(() => _connectedDevice = device);
        discoverServicesAndFindWritable(device);
      } else if (state == BluetoothConnectionState.disconnected) {
        setState(() {
          _connectedDevice = null;
          _writeChar = null;
        });
      }
    });

    // ensure sub cancelled on disconnect (per docs)
    device.cancelWhenDisconnected(sub, delayed: true, next: true);

    setState(() => _connecting = false);
  }

  Future<void> disconnectDevice() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      debugPrint('disconnect error: $e');
    }
    setState(() {
      _connectedDevice = null;
      _writeChar = null;
    });
  }

  Future<void> discoverServicesAndFindWritable(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      BluetoothCharacteristic? candidate;
      // prefer Nordic UART RX UUID if present (common for UART-over-BLE)
      const nusRxUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
      for (final s in services) {
        for (final c in s.characteristics) {
          final uuid = c.uuid.toString().toLowerCase();
          if (uuid.contains(nusRxUuid)) {
            candidate = c;
            break;
          }
          if (candidate == null &&
              (c.properties.write || c.properties.writeWithoutResponse)) {
            candidate = c;
          }
        }
        if (candidate != null) break;
      }
      setState(() => _writeChar = candidate);
    } catch (e) {
      debugPrint('discover services error: $e');
    }
  }

  Future<void> sendCommand() async {
    final device = _connectedDevice;
    final char = _writeChar;
    final text = _cmdController.text;
    if (device == null) {
      _showSnack('未連線裝置');
      return;
    }
    if (char == null) {
      _showSnack('找不到可寫入的 characteristic');
      return;
    }
    if (text.isEmpty) {
      _showSnack('指令為空');
      return;
    }

    final bytes = utf8.encode(text);
    final withoutResponse = char.properties.writeWithoutResponse;
    const chunkSize = 20; // safe default
    int offset = 0;
    try {
      while (offset < bytes.length) {
        final end =
            (offset + chunkSize < bytes.length)
                ? offset + chunkSize
                : bytes.length;
        final chunk = Uint8List.fromList(bytes.sublist(offset, end));
        await char.write(chunk, withoutResponse: withoutResponse);
        offset = end;
        await Future.delayed(const Duration(milliseconds: 8));
      }
      _showSnack('已傳送: $text');
    } catch (e) {
      _showSnack('傳送失敗: $e');
    }
  }

  void _showSnack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Widget _deviceTile(ScanResult r) {
    final name =
        r.device.name.isNotEmpty ? r.device.name : r.device.id.toString();
    return ListTile(
      title: Text(name),
      subtitle: Text('RSSI: ${r.rssi}'),
      trailing: ElevatedButton(
        onPressed:
            (_connecting || _connectedDevice != null)
                ? null
                : () => connectToDevice(r.device),
        child: const Text('Connect'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = _connectedDevice != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Rehabilitation Hand (BLE)')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Baud:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedBaud,
                  items:
                      ['9600', '19200', '38400', '115200']
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text('$b bps'),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedBaud = v ?? '9600'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed:
                      _scanning ? stopScan : () => startScan(timeoutSeconds: 5),
                  child: Text(_scanning ? 'Stop Scan' : 'Scan'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  _scanResults.isEmpty
                      ? const Center(child: Text('No devices found (try Scan)'))
                      : ListView.separated(
                        itemCount: _scanResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _deviceTile(_scanResults[i]),
                      ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cmdController,
              decoration: const InputDecoration(
                labelText: 'Command',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: connected ? sendCommand : null,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
                const SizedBox(width: 12),
                connected
                    ? ElevatedButton.icon(
                      onPressed: disconnectDevice,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    )
                    : const SizedBox(),
              ],
            ),
            const SizedBox(height: 8),
            connected
                ? Text(
                  'Connected to ${_connectedDevice!.name.isNotEmpty ? _connectedDevice!.name : _connectedDevice!.id}',
                )
                : const Text('Not connected'),
          ],
        ),
      ),
    );
  }
}
