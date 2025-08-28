import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/services/motion_storage_service.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';
import 'package:rehabilitation_hand/widgets/common/top_snackbar.dart';

class PlaylistMenuSheet extends StatefulWidget {
  final Function(MotionPlaylist) onLoadPlaylist;
  final VoidCallback onNewPlaylist;

  const PlaylistMenuSheet({
    super.key,
    required this.onLoadPlaylist,
    required this.onNewPlaylist,
  });

  @override
  State<PlaylistMenuSheet> createState() => _PlaylistMenuSheetState();
}

class _PlaylistMenuSheetState extends State<PlaylistMenuSheet> {
  late List<MotionPlaylist> _playlists;

  @override
  void initState() {
    super.initState();
    _playlists = List.from(
      Provider.of<MotionStorageService>(context, listen: false).playlists,
    );
  }

  void _showDeletePlaylistConfirmation(MotionPlaylist playlist) async {
    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('確認刪除'),
            content: Text('確定要刪除播放列表 "${playlist.name}" 嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              CommonButton(
                label: '刪除',
                onPressed: () => Navigator.pop(context, true),
                type: CommonButtonType.solid,
                shape: CommonButtonShape.capsule,
                color: Colors.red,
                textColor: Colors.white,
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await storageService.deletePlaylist(playlist.id);
        showTopSnackBar(context, '播放列表 "${playlist.name}" 已刪除');
        setState(() {
          _playlists.removeWhere((p) => p.id == playlist.id);
        });
      } catch (e) {
        showTopSnackBar(
          context,
          '刪除失敗: $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<MotionStorageService>(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '管理播放列表',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '點擊以載入，長按以拖曳排序。',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onNewPlaylist();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新增播放列表'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    backgroundColor: AppColors.card(context),
                  ),
                ),
              ),
              Expanded(
                child:
                    _playlists.isEmpty
                        ? const Center(
                          child: Text(
                            '沒有已儲存的播放列表',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                        : ReorderableListView.builder(
                          scrollController: scrollController,
                          itemCount: _playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = _playlists[index];
                            final validCount =
                                playlist.items
                                    .where(
                                      (item) =>
                                          storageService.getTemplateById(
                                            item.templateId,
                                          ) !=
                                          null,
                                    )
                                    .length;

                            return Card(
                              key: ValueKey(playlist.id),
                              color: AppColors.card(context),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(playlist.name),
                                subtitle: Text('$validCount 個動作'),
                                leading: const Icon(
                                  Icons.playlist_play_rounded,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed:
                                      () => _showDeletePlaylistConfirmation(
                                        playlist,
                                      ),
                                ),
                                onTap: () {
                                  widget.onLoadPlaylist(playlist);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                          onReorder: (oldIndex, newIndex) async {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = _playlists.removeAt(oldIndex);
                              _playlists.insert(newIndex, item);
                            });
                            try {
                              await storageService.saveAllPlaylists(_playlists);
                              showTopSnackBar(context, '播放列表順序已更新');
                            } catch (e) {
                              showTopSnackBar(
                                context,
                                '順序儲存失敗: $e',
                                backgroundColor: Colors.red,
                                icon: Icons.error,
                              );
                            }
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
