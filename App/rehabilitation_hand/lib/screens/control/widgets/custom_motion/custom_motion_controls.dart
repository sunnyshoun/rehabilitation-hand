import 'package:flutter/material.dart';
import 'package:rehabilitation_hand/config/constants.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';

class CustomMotionControls extends StatelessWidget {
  final bool isEditing;
  final bool isConnected;
  final VoidCallback onSaveMotion;
  final VoidCallback onExecuteMotion;
  final VoidCallback onReset;

  const CustomMotionControls({
    super.key,
    required this.isEditing,
    required this.isConnected,
    required this.onSaveMotion,
    required this.onExecuteMotion,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttons = _buildControlButtons(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            screenWidth > AppConstants.tabletBreakpoint
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: buttons,
                )
                : Column(
                  children:
                      buttons
                          .map(
                            (btn) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: SizedBox(
                                width: double.infinity,
                                child: btn,
                              ),
                            ),
                          )
                          .toList(),
                ),
      ),
    );
  }

  List<Widget> _buildControlButtons(BuildContext context) {
    return [
      CommonButton(
        label: isEditing ? '更新動作' : '儲存動作',
        onPressed: onSaveMotion,
        type: CommonButtonType.solid,
        shape: CommonButtonShape.capsule,
        color:
            isEditing
                ? AppColors.button(context, Colors.orange)
                : AppColors.blueButton(context),
        textColor: Colors.white,
        icon: isEditing ? Icons.update : Icons.save,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      Tooltip(
        message: isConnected ? '發送動作指令' : AppStrings.bluetoothNotConnected,
        child: CommonButton(
          label: '執行動作',
          onPressed: isConnected ? onExecuteMotion : null,
          type: CommonButtonType.solid,
          shape: CommonButtonShape.capsule,
          color: isConnected ? AppColors.success : Colors.grey.shade300,
          textColor: Colors.white,
          icon: Icons.play_arrow,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      CommonButton(
        label: AppStrings.reset,
        onPressed: onReset,
        type: CommonButtonType.transparent,
        shape: CommonButtonShape.capsule,
        textColor: Colors.red,
        icon: Icons.refresh,
      ),
    ];
  }
}
