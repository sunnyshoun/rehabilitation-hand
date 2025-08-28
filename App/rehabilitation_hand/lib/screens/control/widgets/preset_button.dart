import 'package:flutter/material.dart';
import 'package:rehabilitation_hand/config/themes.dart';

class PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PresetButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final buttonColor = AppColors.button(context, Colors.deepPurple);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide(color: buttonColor, width: 2),
        foregroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 28), // 設置最小高度
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
