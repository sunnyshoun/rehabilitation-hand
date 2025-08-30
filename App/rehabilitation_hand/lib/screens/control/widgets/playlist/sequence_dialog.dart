import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/widgets/common/duration_number_picker.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/services/playlist_player_service.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';
import 'package:rehabilitation_hand/widgets/common/top_snackbar.dart';

class SequenceDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sectionBackground(context),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 400,
        child: Consumer<PlaylistPlayerService>(
          builder: (context, player, child) {
            return Column(
              children: [
                // Title moved inside Consumer to access player state
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '序列內容',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!player.isPlaying)
                        CommonButton(
                          label: '清除全部',
                          onPressed: () {
                            Navigator.pop(context);
                            onClearSequence();
                          },
                          type: CommonButtonType.outline,
                          shape: CommonButtonShape.capsule,
                          color: Colors.red,
                          textColor: Colors.red,
                          icon: Icons.clear_all,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('總共 ${player.sequence.length} 個動作'),
                      Text(
                        '總時長: ${player.durations.fold(0, (sum, d) => sum + d)} 秒',
                      ),
                    ],
                  ),
                ),
                if (player.isPlaying)
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
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '正在播放: ${player.currentPlayingIndex + 1} / ${player.sequence.length}',
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
                      player.sequence.isEmpty
                          ? const Center(child: Text('序列已清空'))
                          : player.isPlaying
                          ? _buildPlayingList(context, player)
                          : _buildReorderableList(context, player),
                ),
              ],
            );
          },
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

  // 決定每個項目的trailing按鈕應該顯示什麼
  Widget _buildTrailingButton(
    BuildContext context,
    PlaylistPlayerService player,
    int index,
  ) {
    final isCurrentPlayingItem = index == player.currentPlayingIndex;

    // 播放中
    if (player.isPlaying) {
      if (isCurrentPlayingItem) {
        // 如果是當前正在播放的項目，不顯示任何按鈕
        return const SizedBox(width: 48); // 佔位，保持對齊
      } else {
        // 如果不是當前播放的項目，顯示跳轉按鈕
        return IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.blue),
          tooltip: '跳轉至此動作',
          onPressed: () {
            player.jumpToMotion(index);
            Navigator.of(context).pop(); // 點擊後關閉對話框
          },
        );
      }
    }
    // 非播放中，顯示移除按鈕
    else {
      return IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
        onPressed: () => onRemoveItem(index),
      );
    }
  }

  Widget _buildPlayingList(BuildContext context, PlaylistPlayerService player) {
    return ListView.builder(
      itemCount: player.sequence.length,
      itemBuilder: (context, index) {
        final template = player.sequence[index];
        final isCurrentPlaying = index == player.currentPlayingIndex;

        return Card(
          color:
              isCurrentPlaying
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.green.shade700.withValues(alpha: 0.6)
                      : Colors.green.shade100)
                  : AppColors.section(context),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            // 左 12 右 0，讓跳轉/移除按鈕貼齊右側並與非播放列表一致
            contentPadding: const EdgeInsets.only(left: 12.0, right: 0.0),
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: TextStyle(
                      fontWeight:
                          isCurrentPlaying
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),
                if (isCurrentPlaying)
                  const Icon(Icons.play_arrow, color: Colors.green, size: 20),
              ],
            ),
            subtitle: _buildDurationPicker(
              context,
              player.durations[index],
              (newDuration) {
                if (newDuration != null) {
                  onDurationChanged(index, newDuration);
                }
              },
              isCompact: true,
              isEnabled: !player.isPlaying,
            ),
            trailing: _buildTrailingButton(context, player, index),
          ),
        );
      },
    );
  }

  Widget _buildReorderableList(
    BuildContext context,
    PlaylistPlayerService player,
  ) {
    return ReorderableListView.builder(
      itemCount: player.sequence.length,
      itemBuilder: (context, index) {
        final template = player.sequence[index];
        return Card(
          key: ValueKey(template.id + index.toString()),
          color: AppColors.section(context),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 10.0, right: 0.0),
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(template.name),
            subtitle: _buildDurationPicker(context, player.durations[index], (
              newDuration,
            ) {
              if (newDuration != null) {
                onDurationChanged(index, newDuration);
              }
            }),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => onRemoveItem(index),
            ),
          ),
        );
      },
      onReorder: (oldIndex, newIndex) async {
        try {
          await onReorder(oldIndex, newIndex);
        } catch (e) {
          if (!context.mounted) return;
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

  Widget _buildDurationPicker(
    BuildContext context,
    int currentDuration,
    ValueChanged<int?> onDurationChanged, {
    bool isCompact = false,
    bool isEnabled = true,
  }) {
    final theme = Theme.of(context);
    final disabledBg =
        theme.brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade300;
    final disabledBorder =
        theme.brightness == Brightness.dark
            ? Colors.grey.shade600
            : Colors.grey.shade400;
    final disabledText =
        theme.brightness == Brightness.dark
            ? Colors.grey.shade500
            : Colors.grey.shade600;

    final enabledBg = AppColors.section(context);
    final enabledText = AppColors.infoText(context);

    final bgColor = isEnabled ? enabledBg : disabledBg;
    final textColor = isEnabled ? enabledText : disabledText;
    final borderColor =
        isEnabled ? Colors.grey.withValues(alpha: 0.5) : disabledBorder;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap:
              isEnabled
                  ? () {
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
                                child: DurationNumberPicker(
                                  initial: currentDuration,
                                  onChanged: (v) => onDurationChanged(v),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  : null,
          splashColor: isEnabled ? null : Colors.transparent,
          hoverColor: isEnabled ? null : Colors.transparent,
          highlightColor: isEnabled ? null : Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            // 縮短內部水平間距
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: textColor),
                const SizedBox(width: 6),
                Text('$currentDuration 秒', style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 時間選擇器使用自訂 ListWheelScrollView 實作，已支援播放時禁用灰階顯示。
