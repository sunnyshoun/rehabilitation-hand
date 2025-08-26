import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/motion_model.dart';
import '../services/bluetooth_service.dart';

class MotionTemplatesTab extends StatefulWidget {
  const MotionTemplatesTab({super.key});

  @override
  State<MotionTemplatesTab> createState() => _MotionTemplatesTabState();
}

class _MotionTemplatesTabState extends State<MotionTemplatesTab> {
  final List<MotionTemplate> _templates = [
    MotionTemplate(
      id: '1',
      name: '握拳',
      positions: [
        FingerPosition(
          thumb: FingerState.contracted,
          index: FingerState.contracted,
          middle: FingerState.contracted,
          ring: FingerState.contracted,
          pinky: FingerState.contracted,
        ),
      ],
      createdAt: DateTime.now(),
    ),
    MotionTemplate(
      id: '2',
      name: '張開',
      positions: [
        FingerPosition(
          thumb: FingerState.extended,
          index: FingerState.extended,
          middle: FingerState.extended,
          ring: FingerState.extended,
          pinky: FingerState.extended,
        ),
      ],
      createdAt: DateTime.now(),
    ),
    MotionTemplate(
      id: '3',
      name: '指向',
      positions: [
        FingerPosition(
          thumb: FingerState.relaxed,
          index: FingerState.extended,
          middle: FingerState.contracted,
          ring: FingerState.contracted,
          pinky: FingerState.contracted,
        ),
      ],
      createdAt: DateTime.now(),
    ),
  ];

  final List<MotionTemplate> _sequence = [];
  final List<int> _durations = [];

  void _addToSequence(MotionTemplate template) {
    setState(() {
      _sequence.add(template);
      _durations.add(2);
    });
  }

  void _removeFromSequence(int index) {
    setState(() {
      _sequence.removeAt(index);
      _durations.removeAt(index);
    });
  }

  void _updateDuration(int index, int duration) {
    setState(() {
      _durations[index] = duration;
    });
  }

  void _executeSequence() {
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

    // TODO: 實際執行動作序列
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.white),
            SizedBox(width: 8),
            Text('開始執行動作序列'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothService>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        if (isWideScreen) {
          return Row(
            children: [
              SizedBox(width: 300, child: _buildTemplatesList()),
              const VerticalDivider(width: 1),
              Expanded(child: _buildSequenceEditor(btService.connected)),
            ],
          );
        } else {
          return Column(
            children: [
              ExpansionTile(
                title: const Text('動作模板庫'),
                initiallyExpanded: true,
                children: [SizedBox(height: 200, child: _buildTemplatesList())],
              ),
              const Divider(),
              Expanded(child: _buildSequenceEditor(btService.connected)),
            ],
          );
        }
      },
    );
  }

  Widget _buildTemplatesList() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '可用動作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.gesture, size: 20),
                  title: Text(template.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _addToSequence(template),
                    tooltip: '加入序列',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceEditor(bool isConnected) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '動作序列',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    // 執行按鈕 - 根據連線狀態啟用/禁用
                    Tooltip(
                      message: isConnected ? '執行動作序列' : '請先連接藍牙設備',
                      child: ElevatedButton.icon(
                        onPressed:
                            _sequence.isEmpty || !isConnected
                                ? null
                                : _executeSequence,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('執行'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected ? Colors.green : null,
                          foregroundColor: isConnected ? Colors.white : null,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _sequence.isEmpty
                              ? null
                              : () {
                                setState(() {
                                  _sequence.clear();
                                  _durations.clear();
                                });
                              },
                      child: const Text('清空'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 未連線提示
          if (!isConnected)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      '需要連接藍牙設備才能執行動作',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child:
                _sequence.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text('從上方選擇動作加入序列'),
                        ],
                      ),
                    )
                    : ReorderableListView.builder(
                      itemCount: _sequence.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final template = _sequence.removeAt(oldIndex);
                          final duration = _durations.removeAt(oldIndex);
                          _sequence.insert(newIndex, template);
                          _durations.insert(newIndex, duration);
                        });
                      },
                      itemBuilder: (context, index) {
                        return Card(
                          key: ValueKey('$index'),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                            title: Text(
                              '${index + 1}. ${_sequence[index].name}',
                            ),
                            subtitle: Row(
                              children: [
                                const Text('維持時間: '),
                                SizedBox(
                                  width: 80,
                                  child: DropdownButton<int>(
                                    value: _durations[index],
                                    isDense: true,
                                    items:
                                        List.generate(10, (i) => i + 1)
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text('$e 秒'),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _updateDuration(index, value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeFromSequence(index),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
