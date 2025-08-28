import 'package:flutter/material.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/config/constants.dart';
import 'package:rehabilitation_hand/config/themes.dart';

class FingerSlider extends StatelessWidget {
  final int index;
  final String fingerName;
  final FingerState state;
  final ValueChanged<FingerState> onChanged;
  final bool isCompact;

  const FingerSlider({
    super.key,
    required this.index,
    required this.fingerName,
    required this.state,
    required this.onChanged,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          fingerName,
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
                activeTrackColor: _getStateColor(state),
                inactiveTrackColor: Colors.grey[300],
                thumbColor: _getStateColor(state),
                overlayColor: _getStateColor(state).withOpacity(0.3),
              ),
              child: Slider(
                value: _stateToSliderValue(state),
                min: 0,
                max: 2,
                divisions: 2,
                onChanged: (value) {
                  onChanged(_sliderValueToState(value));
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
            color: _getStateColor(state),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStateName(state),
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

  double _stateToSliderValue(FingerState state) {
    return (2 - state.index).toDouble();
  }

  FingerState _sliderValueToState(double value) {
    return FingerState.values[2 - value.toInt()];
  }

  Color _getStateColor(FingerState state) {
    switch (state) {
      case FingerState.extended:
        return AppColors.extendedColor;
      case FingerState.relaxed:
        return AppColors.relaxedColor;
      case FingerState.contracted:
        return AppColors.contractedColor;
    }
  }

  String _getStateName(FingerState state) {
    switch (state) {
      case FingerState.extended:
        return AppStrings.extendedState;
      case FingerState.relaxed:
        return AppStrings.relaxedState;
      case FingerState.contracted:
        return AppStrings.contractedState;
    }
  }
}