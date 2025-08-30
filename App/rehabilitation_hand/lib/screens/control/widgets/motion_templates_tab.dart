import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/services/bluetooth_service.dart';
import 'package:rehabilitation_hand/services/motion_storage_service.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';
import 'package:rehabilitation_hand/widgets/common/top_snackbar.dart';
import 'package:rehabilitation_hand/screens/control/widgets/playlist/playlist_controls_card.dart';
import 'package:rehabilitation_hand/screens/control/widgets/playlist/playlist_menu_sheet.dart';
import 'package:rehabilitation_hand/screens/control/widgets/playlist/save_playlist_dialog.dart';
import 'package:rehabilitation_hand/screens/control/widgets/playlist/sequence_dialog.dart';
import 'package:rehabilitation_hand/screens/control/widgets/playlist/template_actions_overlay.dart';
import 'package:rehabilitation_hand/widgets/motion/motion_library.dart';
import 'package:rehabilitation_hand/services/playlist_player_service.dart';

class MotionTemplatesTab extends StatefulWidget {
  final Function(String)? onEditTemplate;

  const MotionTemplatesTab({super.key, this.onEditTemplate});

  @override
  State<MotionTemplatesTab> createState() => _MotionTemplatesTabState();
}

class _MotionTemplatesTabState extends State<MotionTemplatesTab>
    with AutomaticKeepAliveClientMixin {
  // Key to get the position of the Stack that contains the overlay
  final GlobalKey _stackKey = GlobalKey();

  // State for the highlight overlay
  MotionTemplate? _highlightedTemplate;
  Rect? _highlightedTemplateRect;
  bool _isOverlayVisible = false;

  @override
  bool get wantKeepAlive => true;

  void _addToSequence(MotionTemplate template) {
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    if (playerService.isPlaying) return; // 播放中不允許添加

    playerService.addToSequence(template);
    showTopSnackBar(
      context,
      '"${template.name}" 已加入序列',
      backgroundColor: AppColors.blueButton(context), // 使用統一的藍色
      icon: Icons.add_circle_outline,
    );
  }

  Future<void> _executeSequence() async {
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    final btService = Provider.of<BluetoothService>(context, listen: false);
    if (!btService.connected) {
      showTopSnackBar(
        context,
        '請先連接藍牙設備',
        backgroundColor: Colors.orange,
        icon: Icons.bluetooth_disabled,
      );
      return;
    }
    await playerService.executeSequence();
  }

  void _clearSequence() {
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    if (playerService.isPlaying) return; // 播放中不允許清除

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('確認清除'),
            content: const Text('確定要清除所有序列內的動作嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              CommonButton(
                label: '清除',
                onPressed: () {
                  playerService.clearSequence();
                  Navigator.pop(context);
                  showTopSnackBar(context, '序列已清空');
                },
                type: CommonButtonType.solid,
                shape: CommonButtonShape.capsule,
                color: Colors.red,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _showSequenceDialog() async {
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    if (playerService.sequence.isEmpty) return;
    await showDialog(
      context: context,
      builder: (context) {
        return SequenceDialog(
          sequence: playerService.sequence,
          durations: playerService.durations,
          isPlaying: playerService.isPlaying,
          currentPlayingIndex: playerService.currentPlayingIndex,
          onClearSequence: _clearSequence,
          onReorder: (oldIndex, newIndex) {
            playerService.reorderSequence(oldIndex, newIndex);
          },
          onDurationChanged: (index, newDuration) {
            playerService.updateDuration(index, newDuration);
          },
          onRemoveItem: (index) {
            playerService.removeSequenceItem(index);
          },
        );
      },
    );
  }

  void _savePlaylist() {
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    if (playerService.isPlaying || playerService.sequence.isEmpty) {
      if (playerService.sequence.isEmpty) {
        showTopSnackBar(
          context,
          '動作列表為空，無法儲存',
          backgroundColor: Colors.orange,
          icon: Icons.warning_amber_rounded,
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => SavePlaylistDialog(
            currentPlaylistId: playerService.currentPlaylistId,
            currentPlaylistName: playerService.currentPlaylistName,
            sequence: playerService.sequence,
            durations: playerService.durations,
            onSaveComplete: (id, name) {
              playerService.setPlaylistInfo(id, name);
              // 不要重新載入播放列表，只更新播放列表信息
              // 這樣可以避免播放列表自動切換的問題
            },
          ),
    );
  }

  void _loadPlaylist(MotionPlaylist playlist) {
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    if (playerService.isPlaying) return; // 播放中不允許載入

    playerService.loadPlaylist(playlist);
    showTopSnackBar(
      context,
      '已載入動作列表 "${playlist.name}"',
      backgroundColor: AppColors.blueButton(context), // 使用統一的藍色
      icon: Icons.playlist_play,
    );
  }

  void _newPlaylist() {
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    if (playerService.isPlaying) return; // 播放中不允許新增

    playerService.newPlaylist();
  }

  void _showPlaylistMenu() {
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    if (playerService.isPlaying) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sectionBackground(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => PlaylistMenuSheet(
            onLoadPlaylist: _loadPlaylist,
            onNewPlaylist: () {
              _newPlaylist();
              showTopSnackBar(
                context,
                '已開啟新的動作列表',
                icon: Icons.add_circle,
                backgroundColor: AppColors.blueButton(context),
              );
            },
          ),
    );
  }

  void _showDeleteConfirmationDialog(
    String title,
    String content,
    VoidCallback onConfirm,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
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
      onConfirm();
    }
  }

  void _deleteTemplate(MotionTemplate template) {
    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    _showDeleteConfirmationDialog(
      '確認刪除',
      '確定要刪除動作 "${template.name}" 嗎？',
      () async {
        try {
          await storageService.deleteTemplate(template.id);
          if (!mounted) return; // Guard context usage after async gap
          // Also remove from the sequence in the player service
          final index = playerService.sequence.indexWhere(
            (t) => t.id == template.id,
          );
          if (index != -1) {
            playerService.removeSequenceItem(index);
          }
          showTopSnackBar(context, '動作 "${template.name}" 已刪除');
        } catch (e) {
          if (!mounted) return; // Guard context usage after async gap
          showTopSnackBar(
            context,
            '刪除失敗: $e',
            backgroundColor: Colors.red,
            icon: Icons.error_outline,
          );
        }
      },
    );
  }

  void _showActionsForTemplate(GlobalKey key, MotionTemplate template) {
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    if (playerService.isPlaying) return; // 播放中不允許顯示動作選項

    final RenderBox? stackRenderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? itemRenderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (stackRenderBox == null || itemRenderBox == null) return;

    final position = itemRenderBox.localToGlobal(
      Offset.zero,
      ancestor: stackRenderBox,
    );
    final size = itemRenderBox.size;

    setState(() {
      _highlightedTemplate = template;
      _highlightedTemplateRect = Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );
      _isOverlayVisible = true;
    });
  }

  void _hideActions() {
    setState(() {
      _isOverlayVisible = false;
    });
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _highlightedTemplate = null;
          _highlightedTemplateRect = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final btService = Provider.of<BluetoothService>(context);
    final playerService = Provider.of<PlaylistPlayerService>(context);
    final isConnected = btService.connected;

    Provider.of<MotionStorageService>(context);

    return Stack(
      key: _stackKey,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AbsorbPointer(
                absorbing: playerService.isPlaying,
                child: MotionLibrarySection(
                  onAddToSequence: _addToSequence,
                  onEditTemplate:
                      playerService.isPlaying ? null : widget.onEditTemplate,
                  onShowActions: _showActionsForTemplate,
                  isPlaying: playerService.isPlaying,
                ),
              ),
              const SizedBox(height: 16),
              PlaylistControlsCard(
                currentPlaylistName: playerService.currentPlaylistName,
                sequenceLength: playerService.sequence.length,
                isPlaying: playerService.isPlaying,
                isConnected: isConnected,
                currentPlayingIndex: playerService.currentPlayingIndex,
                onExecuteSequence: _executeSequence,
                onShowPlaylistMenu: _showPlaylistMenu,
                onShowSequenceDialog: _showSequenceDialog,
                onSavePlaylist: _savePlaylist,
                onStopSequence: () => playerService.stopPlaying(),
              ),
            ],
          ),
        ),
        TemplateActionsOverlay(
          isVisible: _isOverlayVisible,
          highlightedTemplate: _highlightedTemplate,
          highlightedTemplateRect: _highlightedTemplateRect,
          onHide: _hideActions,
          onEdit: (templateId) {
            widget.onEditTemplate?.call(templateId);
          },
          onDelete: _deleteTemplate,
        ),
      ],
    );
  }
}
