import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/config/constants.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/core/extensions/context_extensions.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/services/motion_storage_service.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';

class SaveMotionDialog extends StatefulWidget {
  final bool isEditing;
  final MotionTemplate? editingTemplate;
  final List<FingerState> fingerStates;
  final VoidCallback onSaveComplete;

  const SaveMotionDialog({
    super.key,
    required this.isEditing,
    this.editingTemplate,
    required this.fingerStates,
    required this.onSaveComplete,
  });

  @override
  State<SaveMotionDialog> createState() => _SaveMotionDialogState();
}

class _SaveMotionDialogState extends State<SaveMotionDialog> {
  late String _tempName;
  String? _errorText;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _tempName = widget.isEditing ? widget.editingTemplate!.name : '';
    _nameController = TextEditingController(text: _tempName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateName(String value) {
    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    setState(() {
      _tempName = value;
      if (value.isNotEmpty) {
        final isDuplicate = storageService.isNameTaken(
          value,
          excludeId: widget.isEditing ? widget.editingTemplate?.id : null,
        );
        _errorText = isDuplicate ? AppStrings.nameAlreadyExists : null;
      } else {
        _errorText = null;
      }
    });
  }

  Future<void> _onSave() async {
    if (_tempName.isEmpty || _errorText != null) return;

    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    try {
      final position = FingerPosition(
        thumb: widget.fingerStates[0],
        index: widget.fingerStates[1],
        middle: widget.fingerStates[2],
        ring: widget.fingerStates[3],
        pinky: widget.fingerStates[4],
      );

      final template = MotionTemplate(
        id:
            widget.isEditing
                ? widget.editingTemplate!.id
                : 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _tempName,
        positions: [position],
        createdAt:
            widget.isEditing
                ? widget.editingTemplate!.createdAt
                : DateTime.now(),
      );

      await storageService.saveTemplate(template);
      if (mounted) {
        Navigator.pop(context);
        context.showSuccessMessage(
          widget.isEditing ? '動作 "$_tempName" 已更新' : '動作 "$_tempName" 已儲存',
        );
      }
      widget.onSaveComplete();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        context.showErrorMessage('儲存失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sectionBackground(context),
      title: Text(widget.isEditing ? '更新動作' : '儲存動作'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '動作名稱',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: TextStyle(color: AppColors.infoText(context)),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.infoText(context),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.infoText(context),
                  width: 2,
                ),
              ),
              errorText: _errorText,
            ),
            onChanged: _validateName,
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
          label: widget.isEditing ? AppStrings.update : AppStrings.save,
          onPressed: _onSave,
          type: CommonButtonType.solid,
          shape: CommonButtonShape.capsule,
          color:
              widget.isEditing
                  ? AppColors.button(context, Colors.orange)
                  : AppColors.blueButton(context),
          textColor: Colors.white,
        ),
      ],
    );
  }
}
