import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../models/motion_model.dart';
import '../services/motion_storage_service.dart';
import 'top_snackbar.dart';

// ====== Motion Library Section Widget ======
class MotionLibrarySection extends StatefulWidget {
  final Function(MotionTemplate) onAddToSequence;
  final Function(String)? onEditTemplate;
  final Function(MotionTemplate, MotionStorageService) onDeleteTemplate;
  final Function(GlobalKey, MotionTemplate) onShowActions;

  const MotionLibrarySection({
    super.key,
    required this.onAddToSequence,
    this.onEditTemplate,
    required this.onDeleteTemplate,
    required this.onShowActions,
  });

  @override
  State<MotionLibrarySection> createState() => _MotionLibrarySectionState();
}

class _MotionLibrarySectionState extends State<MotionLibrarySection> {
  bool _isLibraryExpanded = true;
  final Map<String, GlobalKey> _templateKeys = {};

  GlobalKey _getKeyForTemplate(String templateId) {
    _templateKeys.putIfAbsent(templateId, () => GlobalKey());
    return _templateKeys[templateId]!;
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<MotionStorageService>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.5;

    return Card(
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.library_books, size: 28),
            title: const Text(
              '動作庫',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(
                _isLibraryExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed:
                  () =>
                      setState(() => _isLibraryExpanded = !_isLibraryExpanded),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '預設動作 (長按拖曳排序)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildReorderableGrid(
                      templates: storageService.defaultTemplates,
                      isCustom: false,
                      onReorder: (oldIndex, newIndex) async {
                        await storageService.reorderDefaultTemplate(
                          oldIndex,
                          newIndex,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '自訂動作 (長按拖曳排序)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (storageService.customTemplates.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            '沒有自訂動作',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      _buildReorderableGrid(
                        templates: storageService.customTemplates,
                        isCustom: true,
                        onReorder: (oldIndex, newIndex) async {
                          await storageService.reorderTemplate(
                            oldIndex,
                            newIndex,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            crossFadeState:
                _isLibraryExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableGrid({
    required List<MotionTemplate> templates,
    required bool isCustom,
    required Future<void> Function(int, int) onReorder,
  }) {
    return ReorderableGridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final GlobalKey globalKey = _getKeyForTemplate(template.id);

        // *** KEY FIX: Simplified structure to avoid GlobalKey conflicts ***
        return TemplateCard(
          key: ValueKey(template.id), // Required for ReorderableGridView
          template: template,
          isCustom: isCustom,
          actionGlobalKey:
              globalKey, // Pass the GlobalKey as a separate parameter
          onTap: () => widget.onAddToSequence(template),
          onShowActions: () => widget.onShowActions(globalKey, template),
        );
      },
      onReorder: (oldIndex, newIndex) async {
        try {
          await onReorder(oldIndex, newIndex);
        } catch (e) {
          showTopSnackBar(
            context,
            '順序儲存失敗: $e',
            backgroundColor: Colors.red,
            icon: Icons.error,
          );
        }
      },
    );
  }
}

// ====== Reusable Template Card Widget (SIMPLIFIED TO AVOID KEY CONFLICTS) ======
class TemplateCard extends StatefulWidget {
  final MotionTemplate template;
  final bool isCustom;
  final bool isHighlighted;
  final GlobalKey?
  actionGlobalKey; // Optional GlobalKey only for action positioning
  final VoidCallback? onTap;
  final VoidCallback? onShowActions;

  const TemplateCard({
    super.key, // This will be the ValueKey for ReorderableGridView
    required this.template,
    this.isCustom = false,
    this.isHighlighted = false,
    this.actionGlobalKey, // Only used when we need to track position for actions
    this.onTap,
    this.onShowActions,
  });

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
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
    final Color baseColor = widget.isCustom ? Colors.purple : Colors.blue;
    final Color splashColor =
        widget.isCustom ? Colors.purple.shade100 : Colors.blue.shade100;
    final Color highlightColor =
        widget.isCustom
            ? Colors.purple.shade100.withAlpha(150)
            : Colors.blue.shade100.withAlpha(150);

    // *** KEY FIX: Only use GlobalKey when specifically needed for action positioning ***
    return Card(
      key:
          widget
              .actionGlobalKey, // Only apply GlobalKey when needed for actions
      elevation: widget.isHighlighted ? 12 : 2,
      clipBehavior: Clip.antiAlias,
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
                  if (widget.isCustom)
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
