import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/services/bluetooth_service.dart';
import 'package:rehabilitation_hand/services/motion_storage_service.dart';
import 'package:rehabilitation_hand/core/extensions/context_extensions.dart';
import 'package:rehabilitation_hand/config/constants.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'finger_control_card.dart';

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

  void _executeMotion() {
    final btService = Provider.of<BluetoothService>(context, listen: false);

    if (!btService.connected) {
      context.showWarningMessage(AppStrings.bluetoothNotConnected);
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
    context.showSuccessMessage('動作指令已發送');
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
                      floatingLabelBehavior:
                          FloatingLabelBehavior.always, // 標籤永遠浮在外框上
                      labelStyle: TextStyle(color: Colors.blue), // 標籤顏色
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
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
                          errorText =
                              isDuplicate ? AppStrings.nameAlreadyExists : null;
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
                CommonButton(
                  label: AppStrings.cancel,
                  onPressed: () => Navigator.pop(context),
                  type: CommonButtonType.transparent,
                ),
                CommonButton(
                  label: _isEditing ? AppStrings.update : AppStrings.save,
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

                              context.showSuccessMessage(
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
                              context.showErrorMessage('儲存失敗: $e');
                            }
                          },
                  type: CommonButtonType.solid,
                  shape: CommonButtonShape.capsule,
                  color:
                      _isEditing
                          ? Colors.orange
                          : Theme.of(context).primaryColor,
                  textColor: Colors.white,
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
        final isCompact =
            constraints.maxHeight < AppConstants.compactHeightBreakpoint;
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
                    color: AppColors.infoBackground,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
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
              FingerControlCard(
                fingerStates: _fingerStates,
                onStateChanged: (index, state) {
                  setState(() {
                    _fingerStates[index] = state;
                  });
                },
                onPresetPressed: (preset) {
                  setState(() {
                    switch (preset) {
                      case 'relax':
                        _fingerStates.fillRange(0, 5, FingerState.relaxed);
                        break;
                      case 'fist':
                        _fingerStates.fillRange(0, 5, FingerState.contracted);
                        break;
                      case 'open':
                        _fingerStates.fillRange(0, 5, FingerState.extended);
                        break;
                    }
                  });
                },
                isCompact: isCompact,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      screenWidth > AppConstants.tabletBreakpoint
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
      CommonButton(
        label: _isEditing ? '更新動作' : '儲存動作',
        onPressed: _saveMotion,
        type: CommonButtonType.solid,
        shape: CommonButtonShape.capsule,
        color: _isEditing ? Colors.orange : Theme.of(context).primaryColor,
        textColor: Colors.white,
        icon: Icon(_isEditing ? Icons.update : Icons.save, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      Tooltip(
        message: isConnected ? '發送動作指令' : AppStrings.bluetoothNotConnected,
        child: CommonButton(
          label: '執行動作',
          onPressed: isConnected ? _executeMotion : null,
          type: CommonButtonType.solid,
          shape: CommonButtonShape.capsule,
          color: isConnected ? AppColors.connectedColor : Colors.grey.shade300,
          textColor: Colors.white,
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      CommonButton(
        label: AppStrings.reset,
        onPressed: () {
          setState(() {
            _fingerStates.fillRange(0, 5, FingerState.relaxed);
          });
        },
        type: CommonButtonType.transparent,
        shape: CommonButtonShape.capsule,
        textColor: Colors.red,
        icon: const Icon(Icons.refresh, color: Colors.red),
      ),
    ];
  }
}
