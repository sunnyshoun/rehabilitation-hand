import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/motion_model.dart';
import '../services/bluetooth_service.dart';

class CustomMotionTab extends StatefulWidget {
  const CustomMotionTab({super.key});

  @override
  State<CustomMotionTab> createState() => _CustomMotionTabState();
}

class _CustomMotionTabState extends State<CustomMotionTab> {
  final List<FingerState> _fingerStates = List.filled(5, FingerState.relaxed);
  final List<String> _fingerNames = ['拇指', '食指', '中指', '無名指', '小指'];
  String _motionName = '';

  Widget _buildFingerSlider(int index, bool isCompact) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _fingerNames[index],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: isCompact ? 30 : 40,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: isCompact ? 15 : 20,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: isCompact ? 25 : 30,
                ),
                activeTrackColor: _getStateColor(_fingerStates[index]),
                inactiveTrackColor: Colors.grey[300],
                thumbColor: _getStateColor(_fingerStates[index]),
              ),
              child: Slider(
                value: _fingerStates[index].index.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                onChanged: (value) {
                  setState(() {
                    _fingerStates[index] = FingerState.values[value.toInt()];
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: _getStateColor(_fingerStates[index]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStateName(_fingerStates[index]),
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 10 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStateColor(FingerState state) {
    switch (state) {
      case FingerState.extended:
        return Colors.green;
      case FingerState.relaxed:
        return Colors.orange;
      case FingerState.contracted:
        return Colors.red;
    }
  }

  String _getStateName(FingerState state) {
    switch (state) {
      case FingerState.extended:
        return '伸展';
      case FingerState.relaxed:
        return '放鬆';
      case FingerState.contracted:
        return '收緊';
    }
  }

  void _executeMotion() {
    final btService = Provider.of<BluetoothService>(context, listen: false);

    if (!btService.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.bluetooth_disabled, color: Colors.white),
              SizedBox(width: 8),
              Text('請先連接藍牙設備'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final position = FingerPosition(
      thumb: _fingerStates[0],
      index: _fingerStates[1],
      middle: _fingerStates[2],
      ring: _fingerStates[3],
      pinky: _fingerStates[4],
    );

    btService.sendFingerPosition(position);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.send, color: Colors.white),
            SizedBox(width: 8),
            Text('動作指令已發送'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveMotion() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('儲存動作'),
            content: TextField(
              decoration: const InputDecoration(
                labelText: '動作名稱',
                hintText: '輸入動作名稱',
              ),
              onChanged: (value) => _motionName = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_motionName.isNotEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('動作 "$_motionName" 已儲存')),
                    );
                  }
                },
                child: const Text('儲存'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothService>(context);
    final isConnected = btService.connected;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 600;
        final screenWidth = constraints.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 未連線提示
              if (!isConnected)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '需要連接藍牙設備才能執行動作控制',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // 手指控制區域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        '手指控制',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: isCompact ? 250 : 350,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            5,
                            (index) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _buildFingerSlider(index, isCompact),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 控制按鈕區域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      screenWidth > 600
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _buildControlButtons(isConnected),
                          )
                          : Column(
                            children:
                                _buildControlButtons(isConnected)
                                    .map(
                                      (btn) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: btn,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildControlButtons(bool isConnected) {
    return [
      ElevatedButton.icon(
        onPressed: _saveMotion,
        icon: const Icon(Icons.save),
        label: const Text('儲存動作'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      Tooltip(
        message: isConnected ? '發送動作指令' : '請先連接藍牙設備',
        child: ElevatedButton.icon(
          onPressed: isConnected ? _executeMotion : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('執行動作'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: isConnected ? Colors.green : null,
            foregroundColor: isConnected ? Colors.white : null,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
        ),
      ),
      TextButton.icon(
        onPressed: () {
          setState(() {
            _fingerStates.fillRange(0, 5, FingerState.relaxed);
          });
        },
        icon: const Icon(Icons.refresh),
        label: const Text('重置'),
      ),
    ];
  }
}
