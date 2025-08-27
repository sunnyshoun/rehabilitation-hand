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
                      storageService: storageService,
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
                        storageService: storageService,
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
    required MotionStorageService storageService,
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

        return TemplateCard(
          key: ValueKey(template.id),
          template: template,
          isCustom: isCustom,
          actionGlobalKey: globalKey,
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
      dragWidgetBuilder: (index, child) {
        final template = templates[index];
        final isCustomTemplate = isCustom; // 直接使用傳入的 isCustom 即可，更簡潔

        final Color dragHighlightColor =
            isCustomTemplate ? Colors.purple.shade100 : Colors.blue.shade100;

        return Material(
          elevation: 4.0,
          color: Colors.transparent,
          // ✅ **【新增】**：將陰影顏色和表面著色也設為透明
          shadowColor: Colors.transparent, // 確保陰影本身沒有預設顏色疊加
          surfaceTintColor: Colors.transparent, // 消除任何潛在的表面著色效果
          child: TemplateCard(
            key: ValueKey('dragging_${template.id}'),
            template: template,
            isCustom: isCustomTemplate,
            backgroundColorOverride: dragHighlightColor,
          ),
        );
      },
    );
  }
}

// ====== Reusable Template Card Widget ======
class TemplateCard extends StatefulWidget {
  final MotionTemplate template;
  final bool isCustom;
  final bool isHighlighted;
  final GlobalKey? actionGlobalKey;
  final VoidCallback? onTap;
  final VoidCallback? onShowActions;
  final Color? backgroundColorOverride; // 新增：背景色覆寫參數

  const TemplateCard({
    super.key,
    required this.template,
    this.isCustom = false,
    this.isHighlighted = false,
    this.actionGlobalKey,
    this.onTap,
    this.onShowActions,
    this.backgroundColorOverride, // 新增：在建構子中加入
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

    return Card(
      key: widget.actionGlobalKey,
      elevation: widget.isHighlighted ? 12 : 2,
      clipBehavior: Clip.antiAlias,
      color: widget.backgroundColorOverride, // 修改：使用背景色覆寫
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
