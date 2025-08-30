import 'package:flutter/material.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';

class PlaylistControlsCard extends StatelessWidget {
  final String currentPlaylistName;
  final int sequenceLength;
  final bool isPlaying;
  final bool isConnected;
  final int currentPlayingIndex;
  final VoidCallback onExecuteSequence;
  final VoidCallback onStopSequence;
  final VoidCallback onShowPlaylistMenu;
  final VoidCallback onShowSequenceDialog;
  final VoidCallback onSavePlaylist;

  const PlaylistControlsCard({
    super.key,
    required this.currentPlaylistName,
    required this.sequenceLength,
    required this.isPlaying,
    required this.isConnected,
    required this.currentPlayingIndex,
    required this.onExecuteSequence,
    required this.onStopSequence,
    required this.onShowPlaylistMenu,
    required this.onShowSequenceDialog,
    required this.onSavePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.sectionBackground(context),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.front_hand, size: 28),
            title: const Text(
              '動作列表',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            trailing: CommonButton(
              label: isPlaying ? '停止' : '開始',
              icon: isPlaying ? Icons.stop : Icons.play_arrow,
              onPressed:
                  isPlaying
                      ? onStopSequence
                      : (isConnected && sequenceLength > 0)
                      ? onExecuteSequence
                      : null,
              type: CommonButtonType.solid,
              shape: CommonButtonShape.capsule,
              color:
                  isPlaying
                      ? AppColors.button(context, Colors.red)
                      : (isConnected && sequenceLength > 0)
                      ? AppColors.button(context, Colors.green)
                      : AppColors.button(context, Colors.grey.shade300),
              textColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.section(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 16,
                    color: AppColors.infoText(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentPlaylistName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.infoText(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPlaying && sequenceLength > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentPlayingIndex + 1}/$sequenceLength',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '序列項目: ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.button(context, Colors.deepPurple),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$sequenceLength',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CommonButton(
                    label: '管理',
                    icon: Icons.folder_open,
                    onPressed: isPlaying ? null : onShowPlaylistMenu,
                    type: CommonButtonType.outline,
                    shape: CommonButtonShape.capsule,
                    color: AppColors.button(context, Colors.deepPurple),
                    textColor: AppColors.button(context, Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CommonButton(
                    label: '序列內容',
                    icon: Icons.list_alt,
                    onPressed:
                        sequenceLength == 0 ? null : onShowSequenceDialog,
                    type: CommonButtonType.outline,
                    shape: CommonButtonShape.capsule,
                    color:
                        sequenceLength == 0
                            ? Colors.grey
                            : AppColors.blueButton(context),
                    textColor:
                        sequenceLength == 0
                            ? Colors.grey
                            : AppColors.blueButton(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CommonButton(
                    label: '儲存',
                    icon: Icons.save,
                    onPressed:
                        (sequenceLength == 0 || isPlaying)
                            ? null
                            : onSavePlaylist,
                    type: CommonButtonType.outline,
                    shape: CommonButtonShape.capsule,
                    color:
                        (sequenceLength == 0 || isPlaying)
                            ? Colors.grey
                            : AppColors.blueButton(context),
                    textColor:
                        (sequenceLength == 0 || isPlaying)
                            ? Colors.grey
                            : AppColors.blueButton(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
