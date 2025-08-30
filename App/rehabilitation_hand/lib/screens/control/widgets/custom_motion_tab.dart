import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/core/extensions/context_extensions.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/services/bluetooth_service.dart';
import 'package:rehabilitation_hand/services/motion_storage_service.dart';
import 'package:rehabilitation_hand/services/playlist_player_service.dart';
import 'package:rehabilitation_hand/config/constants.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/screens/control/widgets/custom_motion/custom_motion_controls.dart';
import 'package:rehabilitation_hand/screens/control/widgets/custom_motion/save_motion_dialog.dart';
import 'package:rehabilitation_hand/screens/control/widgets/finger_control_card.dart';

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
    showDialog(
      context: context,
      builder:
          (context) => SaveMotionDialog(
            isEditing: _isEditing,
            editingTemplate: _editingTemplate,
            fingerStates: _fingerStates,
            onSaveComplete: () {
              if (_isEditing) {
                widget.onEditComplete?.call();
              }
              _resetToDefault();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlaylistPlayerService>(context);
    final btService = Provider.of<BluetoothService>(context);
    final isConnected = btService.connected;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxHeight < AppConstants.compactHeightBreakpoint;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_isEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.section(context), // 使用 section 背景（800）
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(
                      color: AppColors.infoText(context).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 20,
                        color: AppColors.infoText(context), // 自適應文字顏色
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '正在編輯: ${_editingTemplate?.name ?? ""}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.infoText(context), // 自適應文字顏色
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
              CustomMotionControls(
                isEditing: _isEditing,
                isConnected: isConnected,
                onSaveMotion: _saveMotion,
                onExecuteMotion: _executeMotion,
                onReset: () {
                  setState(() {
                    _fingerStates.fillRange(0, 5, FingerState.relaxed);
                  });
                },
                isPlaying: playerService.isPlaying,
              ),
            ],
          ),
        );
      },
    );
  }
}
