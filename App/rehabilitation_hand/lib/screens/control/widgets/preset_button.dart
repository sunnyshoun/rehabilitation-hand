import 'package:flutter/material.dart';

class PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PresetButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: const BorderSide(color: Colors.deepPurple, width: 2), // 外框顏色與粗細
        foregroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
