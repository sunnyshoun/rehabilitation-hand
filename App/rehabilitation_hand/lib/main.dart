// lib/main.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:spp_connection_plugin/spp_connection_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SerialMonitorPage(),
    );
  }
}

class SerialMonitorPage extends StatefulWidget {
  const SerialMonitorPage({super.key});
  @override
  State<SerialMonitorPage> createState() => _SerialMonitorPageState();
}

class _SerialMonitorPageState extends State<SerialMonitorPage> {
  final SppConnectionPlugin _bt = SppConnectionPlugin();

  // 掃描與裝置列表
  bool _scanning = false;
  List<BluetoothDeviceModel> _devices = [];
  Timer? _scanTimer;

  // 連線後控制
  bool _connected = false;
  String _log = '';
  final TextEditingController _sendCtrl = TextEditingController();
  final ScrollController _logScroll = ScrollController();

  // Serial Monitor 選項
  bool _hexMode = false;
  String newlineType = TextUtils.newlineCRLF;
  bool _appendCrlf = true;

  @override
  void initState() {
    super.initState();
    _bt.dataStream.listen(_onDataReceived);
    _bt.connectionStateStream.listen((state) {
      setState(() => _connected = state == BluetoothConnectionState.connected);
      if (!_connected) _appendLog('** Disconnected **');
    });
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    bool hasPerm = await _bt.hasPermissions();
    if (!hasPerm) {
      hasPerm = await _bt.requestPermissions();
    }
    if (hasPerm) {
      _scan();
      // Start timer for auto-refresh when not connected
      _scanTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_connected && !_scanning) _scan();
      });
    } else {
      _appendLog('Bluetooth permissions denied');
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _sendCtrl.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  void _onDataReceived(Uint8List data) {
    final text =
        _hexMode
            ? data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')
            : String.fromCharCodes(data);
    _appendLog('[Device] $text');
  }

  void _appendLog(String s) {
    setState(() => _log += '$s\n');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
      }
    });
  }

  void _clearLog() => setState(() => _log = '');

  // Scan paired devices
  Future<void> _scan() async {
    setState(() => _scanning = true);
    final devs = await _bt.getPairedDevices();
    setState(() {
      _devices = devs;
      _scanning = false;
    });
  }

  Future<void> _connect(BluetoothDeviceModel d) async {
    _appendLog('Connecting to ${d.name}...');
    await _bt.connectToDevice(d.address);

    // Set modes
    _bt.setHexMode(_hexMode);
    _bt.setNewlineType(newlineType);

    _appendLog('Connected to ${d.name}');
  }

  void _disconnect() => _bt.disconnect();

  Future<void> _send() async {
    String txt = _sendCtrl.text;
    if (txt.isEmpty) return;

    if (!_hexMode && _appendCrlf) {
      txt += '\r\n';
    }

    if (_hexMode) {
      // Assume input is hex string like '48 65 6C 6C 6F'
      await _bt.sendHex(txt);
      _appendLog('[Me][HEX] $txt');
    } else {
      await _bt.sendText(txt);
      _appendLog('[Me] $txt');
    }

    _sendCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connected ? 'Serial Monitor' : 'Select Device'),
        actions: [
          if (!_connected)
            TextButton(
              onPressed: _scanning ? null : _scan,
              child: Text(
                _scanning ? 'Scanning...' : 'Refresh',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (_connected)
            TextButton(
              onPressed: _disconnect,
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _connected ? _buildMonitor() : _buildDeviceList(),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty && !_scanning) {
      return const Center(
        child: Text(
          'No paired devices found. Pair devices in system settings.',
        ),
      );
    }
    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (_, i) {
        final d = _devices[i];
        return ListTile(
          title: Text(d.name ?? 'Unknown'),
          subtitle: Text(d.address, style: const TextStyle(fontSize: 12)),
          onTap: () => _connect(d),
        );
      },
    );
  }

  Widget _buildMonitor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _hexMode,
              onChanged: (v) {
                setState(() => _hexMode = v ?? false);
                _bt.setHexMode(_hexMode);
              },
            ),
            const Text('Hex Mode'),
            const Spacer(),
            Checkbox(
              value: _appendCrlf,
              onChanged: (v) => setState(() => _appendCrlf = v ?? true),
            ),
            const Text('Append CRLF'),
            IconButton(icon: const Icon(Icons.clear), onPressed: _clearLog),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              controller: _logScroll,
              child: SelectableText(
                _log.isEmpty ? '(No data yet)' : _log,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _sendCtrl,
                decoration: const InputDecoration(
                  labelText: 'Send message',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
          ],
        ),
      ],
    );
  }
}
