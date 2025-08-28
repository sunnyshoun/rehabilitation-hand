import 'package:flutter/material.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/widgets/motion/template_card.dart';

class TemplateActionsOverlay extends StatelessWidget {
  final bool isVisible;
  final MotionTemplate? highlightedTemplate;
  final Rect? highlightedTemplateRect;
  final VoidCallback onHide;
  final Function(String) onEdit;
  final Function(MotionTemplate) onDelete;

  const TemplateActionsOverlay({
    super.key,
    required this.isVisible,
    this.highlightedTemplate,
    this.highlightedTemplateRect,
    required this.onHide,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isVisible && highlightedTemplate == null,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: onHide,
                child: Container(color: Colors.black.withAlpha(153)),
              ),
            ),
            if (highlightedTemplate != null &&
                highlightedTemplateRect != null) ...[
              Positioned(
                top: highlightedTemplateRect!.top,
                left: highlightedTemplateRect!.left,
                width: highlightedTemplateRect!.width,
                height: highlightedTemplateRect!.height,
                child: IgnorePointer(
                  child: TemplateCard(
                    template: highlightedTemplate!,
                    isCustom: true,
                    isHighlighted: true,
                  ),
                ),
              ),
              Positioned(
                top: highlightedTemplateRect!.top - 10,
                left: highlightedTemplateRect!.right - 75,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _ActionButton(
                        icon: Icons.edit,
                        color: Colors.blue,
                        onTap: () {
                          final templateId = highlightedTemplate!.id;
                          onHide();
                          onEdit(templateId);
                        },
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        onTap: () {
                          final template = highlightedTemplate!;
                          onHide();
                          onDelete(template);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      color: color,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
