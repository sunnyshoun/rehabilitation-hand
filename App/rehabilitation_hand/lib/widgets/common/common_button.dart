import 'package:flutter/material.dart';

enum CommonButtonType { solid, outline, transparent }

enum CommonButtonShape { roundedRect, capsule }

class CommonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CommonButtonType type;
  final CommonButtonShape shape;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final IconData? icon;
  final double iconSize;

  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = CommonButtonType.solid,
    this.shape = CommonButtonShape.capsule,
    this.color,
    this.textColor,
    this.padding,
    this.borderRadius = 12,
    this.icon,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    OutlinedBorder buttonShape;
    switch (shape) {
      case CommonButtonShape.capsule:
        buttonShape = const StadiumBorder();
        break;
      case CommonButtonShape.roundedRect:
        buttonShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        );
        break;
    }

    final btnPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    final Widget child =
        icon == null
            ? Text(label)
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color:
                      onPressed == null
                          ? Colors.grey
                          : (textColor ??
                              color ??
                              Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Text(label),
              ],
            );

    switch (type) {
      case CommonButtonType.solid:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            shape: buttonShape,
            padding: btnPadding,
            elevation: 0,
          ),
          child: child,
        );
      case CommonButtonType.outline:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                onPressed == null ? Colors.grey : (textColor ?? color),
            side: BorderSide(
              color:
                  onPressed == null
                      ? Colors.grey
                      : (color ?? Theme.of(context).colorScheme.primary),
              width: 2,
            ),
            shape: buttonShape,
            padding: btnPadding,
          ),
          child: child,
        );
      case CommonButtonType.transparent:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? color,
            shape: buttonShape,
            padding: btnPadding,
            backgroundColor: Colors.transparent,
          ),
          child: child,
        );
    }
  }
}
