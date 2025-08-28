import 'package:flutter/material.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';

class SequenceDialog extends StatefulWidget {
  final List<MotionTemplate> sequence;
  final List<int> durations;
  final bool isPlaying;
  final int currentPlayingIndex;
  final VoidCallback onClearSequence;
  final Function(int, int) onReorder;
  final Function(int, int) onDurationChanged;
  final Function(int) onRemoveItem;

  const SequenceDialog({
    super.key,
    required this.sequence,
    required this.durations,
    required this.isPlaying,
    required this.currentPlayingIndex,
    required this.onClearSequence,
    required this.onReorder,
    required this.onDurationChanged,
    required this.onRemoveItem,
  });

  @override
  State<SequenceDialog> createState() => _SequenceDialogState();
}

class _SequenceDialogState extends State<SequenceDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sectionBackground(context),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('序列內容'),
          if (!widget.isPlaying)
            CommonButton(
              label: '清除全部',
              onPressed: () {
                Navigator.pop(context);
                widget.onClearSequence();
              },
              type: CommonButtonType.outline,
              shape: CommonButtonShape.capsule,
              color: Colors.red,
              textColor: Colors.red,
              icon: Icons.clear_all,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 400,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('總共 ${widget.sequence.length} 個動作'),
                  Text(
                    '總時長: ${widget.durations.fold(0, (sum, d) => sum + d)} 秒',
                  ),
                ],
              ),
            ),
            if (widget.isPlaying)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.section(context)
                          : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '正在播放: ${widget.currentPlayingIndex + 1} / ${widget.sequence.length}',
                      style: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue.shade300
                                : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  widget.sequence.isEmpty
                      ? const Center(child: Text('序列已清空'))
                      : widget.isPlaying
                      ? _buildPlayingList()
                      : _buildReorderableList(),
            ),
          ],
        ),
      ),
      actions: [
        CommonButton(
          label: '完成',
          onPressed: () => Navigator.of(context).pop(),
          type: CommonButtonType.solid,
          shape: CommonButtonShape.capsule,
          color: AppColors.blueButton(context),
          textColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildPlayingList() {
    return ListView.builder(
      itemCount: widget.sequence.length,
      itemBuilder: (context, index) {
        final template = widget.sequence[index];
        final isCurrentPlaying = index == widget.currentPlayingIndex;
        return Card(
          color:
              isCurrentPlaying
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.green.shade700.withOpacity(0.6)
                      : Colors.green.shade100)
                  : AppColors.section(context),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(template.name),
            subtitle: _buildDurationPicker(context, widget.durations[index], (
              newDuration,
            ) {
              if (newDuration != null) {
                widget.onDurationChanged(index, newDuration);
              }
            }, isCompact: true),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => widget.onRemoveItem(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      itemCount: widget.sequence.length,
      itemBuilder: (context, index) {
        final template = widget.sequence[index];
        return Card(
          key: ValueKey(template.id + index.toString()),
          color: AppColors.section(context),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 10.0, right: 0.0),
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(template.name),
            subtitle: _buildDurationPicker(context, widget.durations[index], (
              newDuration,
            ) {
              if (newDuration != null) {
                widget.onDurationChanged(index, newDuration);
              }
            }),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => widget.onRemoveItem(index),
            ),
          ),
        );
      },
      onReorder: widget.onReorder,
    );
  }

  Widget _buildDurationPicker(
    BuildContext context,
    int currentDuration,
    ValueChanged<int?> onDurationChanged, {
    bool isCompact = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return SizedBox(
                  height: 250,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          '選擇持續時間',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          controller: FixedExtentScrollController(
                            initialItem: currentDuration - 1,
                          ),
                          onSelectedItemChanged: (index) {
                            onDurationChanged(index + 1);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              return Center(
                                child: Text(
                                  '${index + 1} 秒',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              );
                            },
                            childCount: 60,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.section(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppColors.infoText(context),
                ),
                const SizedBox(width: 6),
                Text(
                  '$currentDuration 秒',
                  style: TextStyle(color: AppColors.infoText(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
