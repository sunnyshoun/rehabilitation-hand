import 'package:flutter/material.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/config/constants.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/widgets/motion/finger_slider.dart';
import 'package:rehabilitation_hand/screens/control/widgets/custom_motion/preset_button.dart';

class FingerControlCard extends StatelessWidget {
  final List<FingerState> fingerStates;
  final Function(int, FingerState) onStateChanged;
  final Function(String) onPresetPressed;
  final bool isCompact;

  const FingerControlCard({
    super.key,
    required this.fingerStates,
    required this.onStateChanged,
    required this.onPresetPressed,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.sectionBackground(context),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '手指控制',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PresetButton(
                        label: '放鬆',
                        onPressed: () => onPresetPressed('relax'),
                      ),
                      const SizedBox(width: 2),
                      PresetButton(
                        label: AppStrings.fistMotion,
                        onPressed: () => onPresetPressed('fist'),
                      ),
                      const SizedBox(width: 2),
                      PresetButton(
                        label: AppStrings.openMotion,
                        onPressed: () => onPresetPressed('open'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStateIndicators(context),
            const SizedBox(height: 20),
            SizedBox(
              height: isCompact ? 250 : 350,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  5,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FingerSlider(
                        index: index,
                        fingerName: AppStrings.fingerNames[index],
                        state: fingerStates[index],
                        onChanged: (state) => onStateChanged(index, state),
                        isCompact: isCompact,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIndicators(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.section(context),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStateIndicator(
            '上: ${AppStrings.extendedState}',
            AppColors.extendedColor,
          ),
          _buildStateIndicator(
            '中: ${AppStrings.relaxedState}',
            AppColors.relaxedColor,
          ),
          _buildStateIndicator(
            '下: ${AppStrings.contractedState}',
            AppColors.contractedColor,
          ),
        ],
      ),
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
}
