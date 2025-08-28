import 'package:flutter/material.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/config/themes.dart';

class TemplateCard extends StatefulWidget {
  final MotionTemplate template;
  final bool isCustom;
  final bool isHighlighted;
  final GlobalKey? actionGlobalKey;
  final VoidCallback? onTap;
  final VoidCallback? onShowActions;
  final Color? backgroundColorOverride;
  final bool showMoreButton;

  const TemplateCard({
    super.key,
    required this.template,
    this.isCustom = false,
    this.isHighlighted = false,
    this.actionGlobalKey,
    this.onTap,
    this.onShowActions,
    this.backgroundColorOverride,
    this.showMoreButton = true,
  });

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor =
        widget.isCustom
            ? AppColors.customTemplateColor(context)
            : AppColors.defaultTemplateColor(context);
    final Color splashColor =
        widget.isCustom ? Colors.purple.shade100 : Colors.blue.shade100;
    final Color highlightColor =
        widget.isCustom
            ? Colors.purple.shade100.withAlpha(150)
            : Colors.blue.shade100.withAlpha(150);

    return Card(
      key: widget.actionGlobalKey,
      elevation: widget.isHighlighted ? 12 : 2,
      clipBehavior: Clip.antiAlias,
      color: widget.backgroundColorOverride,
      shape:
          widget.isHighlighted
              ? RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).primaryColorLight,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              )
              : null,
      child: InkWell(
        onTap: _handleTap,
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Icon(Icons.gesture, size: 24, color: baseColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.template.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isCustom && widget.showMoreButton)
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onPressed: widget.onShowActions,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      tooltip: '更多選項',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
