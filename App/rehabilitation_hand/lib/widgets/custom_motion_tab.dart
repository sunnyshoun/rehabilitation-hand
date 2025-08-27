import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/motion_model.dart';
import '../services/bluetooth_service.dart';
import '../services/motion_storage_service.dart';
import 'top_snackbar.dart'; // *** NEW: Import the custom snackbar ***

class CustomMotionTab extends StatefulWidget {
  final String? editingTemplateId;
  final VoidCallback? onEditComplete;

  const CustomMotionTab({
    super.key,
    this.editingTemplateId,
    this.onEditComplete,
  });

  @override
  State<CustomMotionTab> createState() => _CustomMotionTabState();
}

class _CustomMotionTabState extends State<CustomMotionTab> {
  List<FingerState> _fingerStates = List.filled(5, FingerState.relaxed);
  final List<String> _fingerNames = ['拇指', '食指', '中指', '無名指', '小指'];
  String _motionName = '';
  bool _isEditing = false;
  MotionTemplate? _editingTemplate;

  @override
  void initState() {
    super.initState();
    if (widget.editingTemplateId != null) {
      _loadTemplateForEditing();
    }
  }

  @override
  void didUpdateWidget(CustomMotionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingTemplateId != oldWidget.editingTemplateId) {
      if (widget.editingTemplateId != null) {
        _loadTemplateForEditing();
      } else {
        _resetToDefault();
      }
    }
  }

  void _loadTemplateForEditing() {
    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    final template = storageService.getTemplateById(widget.editingTemplateId!);

    if (template != null && template.positions.isNotEmpty) {
      setState(() {
        _isEditing = true;
        _editingTemplate = template;
        _motionName = template.name;
        final position = template.positions.first;
        _fingerStates = [
          position.thumb,
          position.index,
          position.middle,
          position.ring,
          position.pinky,
        ];
      });
    }
  }

  void _resetToDefault() {
    setState(() {
      _fingerStates = List.filled(5, FingerState.relaxed);
      _motionName = '';
      _isEditing = false;
      _editingTemplate = null;
    });
  }

  double _stateToSliderValue(FingerState state) {
    return (2 - state.index).toDouble();
  }

  FingerState _sliderValueToState(double value) {
    return FingerState.values[2 - value.toInt()];
  }

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
                overlayColor: _getStateColor(
                  _fingerStates[index],
                ).withOpacity(0.3),
              ),
              child: Slider(
                value: _stateToSliderValue(_fingerStates[index]),
                min: 0,
                max: 2,
                divisions: 2,
                onChanged: (value) {
                  setState(() {
                    _fingerStates[index] = _sliderValueToState(value);
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStateColor(FingerState state) {
    switch (state) {
      case FingerState.extended:
        return Colors.amber;
      case FingerState.relaxed:
        return Colors.green;
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
      // *** MODIFIED: Use top snackbar for notification ***
      showTopSnackBar(
        context,
        '請先連接藍牙設備',
        backgroundColor: Colors.orange,
        icon: Icons.bluetooth_disabled,
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
    // *** MODIFIED: Use top snackbar for notification ***
    showTopSnackBar(
      context,
      '動作指令已發送',
      backgroundColor: Colors.green,
      icon: Icons.send,
    );
  }

  void _saveMotion() {
    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (context) {
        String tempName = _isEditing ? _motionName : '';
        String? errorText;
        final nameController = TextEditingController(text: tempName);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_isEditing ? '更新動作' : '儲存動作'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '動作名稱',
                      hintText: '輸入動作名稱',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      tempName = value;
                      if (value.isNotEmpty) {
                        final isDuplicate = storageService.isNameTaken(
                          value,
                          excludeId: _isEditing ? _editingTemplate?.id : null,
                        );
                        setDialogState(() {
                          errorText = isDuplicate ? '此名稱已存在' : null;
                        });
                      } else {
                        setDialogState(() {
                          errorText = null;
                        });
                      }
                    },
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed:
                      (tempName.isEmpty || errorText != null)
                          ? null
                          : () async {
                            try {
                              final position = FingerPosition(
                                thumb: _fingerStates[0],
                                index: _fingerStates[1],
                                middle: _fingerStates[2],
                                ring: _fingerStates[3],
                                pinky: _fingerStates[4],
                              );

                              final template = MotionTemplate(
                                id:
                                    _isEditing
                                        ? _editingTemplate!.id
                                        : 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                name: tempName,
                                positions: [position],
                                createdAt:
                                    _isEditing
                                        ? _editingTemplate!.createdAt
                                        : DateTime.now(),
                              );

                              await storageService.saveTemplate(template);

                              Navigator.pop(context);

                              // *** MODIFIED: Use top snackbar for notification ***
                              showTopSnackBar(
                                context,
                                _isEditing
                                    ? '動作 "$tempName" 已更新'
                                    : '動作 "$tempName" 已儲存',
                              );

                              if (_isEditing) {
                                setState(() {
                                  _motionName = tempName;
                                });
                                widget.onEditComplete?.call();
                                _resetToDefault();
                              } else {
                                _resetToDefault();
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              // *** MODIFIED: Use top snackbar for notification ***
                              showTopSnackBar(
                                context,
                                '儲存失敗: $e',
                                backgroundColor: Colors.red,
                                icon: Icons.error_outline,
                              );
                            }
                          },
                  child: Text(_isEditing ? '更新' : '儲存'),
                ),
              ],
            );
          },
        );
      },
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
              if (_isEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '正在編輯: ${_editingTemplate?.name ?? ""}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.onEditComplete?.call();
                          _resetToDefault();
                        },
                        child: const Text('取消編輯'),
                      ),
                    ],
                  ),
                ),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '手指控制',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              _PresetButton(
                                label: '全部放鬆',
                                onPressed: () {
                                  setState(() {
                                    _fingerStates.fillRange(
                                      0,
                                      5,
                                      FingerState.relaxed,
                                    );
                                  });
                                },
                              ),
                              _PresetButton(
                                label: '握拳',
                                onPressed: () {
                                  setState(() {
                                    _fingerStates.fillRange(
                                      0,
                                      5,
                                      FingerState.contracted,
                                    );
                                  });
                                },
                              ),
                              _PresetButton(
                                label: '張開',
                                onPressed: () {
                                  setState(() {
                                    _fingerStates.fillRange(
                                      0,
                                      5,
                                      FingerState.extended,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStateIndicator('上: 伸展', Colors.amber),
                            _buildStateIndicator('中: 放鬆', Colors.green),
                            _buildStateIndicator('下: 收緊', Colors.red),
                          ],
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
              Card(
                elevation: 2,
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

  Widget _buildStateIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  List<Widget> _buildControlButtons(bool isConnected) {
    return [
      ElevatedButton.icon(
        onPressed: _saveMotion,
        icon: Icon(_isEditing ? Icons.update : Icons.save),
        label: Text(_isEditing ? '更新動作' : '儲存動作'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: _isEditing ? Colors.orange : null,
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

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PresetButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
