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

  // Sequence and playlist state
  final List<MotionTemplate> _sequence = [];
  final List<int> _durations = [];
  bool _isPlaying = false;
  bool _isPaused = false;
  int _currentPlayingIndex = -1;
  Timer? _playTimer;
  String? _currentPlaylistId;
  String _currentPlaylistName = '未命名播放列表';

  // State for the highlight overlay
  MotionTemplate? _highlightedTemplate;
  Rect? _highlightedTemplateRect;
  bool _isOverlayVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  void _addToSequence(MotionTemplate template) {
    if (_isPlaying) return; // 播放中不允許添加

    setState(() {
      _sequence.add(template);
      _durations.add(2); // Default duration
    });
    showTopSnackBar(
      context,
      '"${template.name}" 已加入序列',
      backgroundColor: AppColors.blueButton(context), // 使用統一的藍色
      icon: Icons.add_circle_outline,
    );
  }

  Future<void> _executeSequence() async {
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

    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _currentPlayingIndex = 0;
    });

    await _playCurrentMotion();
  }

  Future<void> _playCurrentMotion() async {
    if (!_isPlaying || _isPaused || _currentPlayingIndex >= _sequence.length) {
      if (_currentPlayingIndex >= _sequence.length) {
        _stopPlaying();
      }
      return;
    }

    final btService = Provider.of<BluetoothService>(context, listen: false);
    final template = _sequence[_currentPlayingIndex];

    if (template.positions.isNotEmpty) {
      final position = template.positions.first;
      await btService.sendFingerPosition(position);

      _playTimer?.cancel();
      _playTimer = Timer(
        Duration(seconds: _durations[_currentPlayingIndex]),
        () {
          if (_isPlaying && !_isPaused && mounted) {
            setState(() {
              _currentPlayingIndex++;
            });
            _playCurrentMotion();
          }
        },
      );
    }
  }

  void _pausePlaying() {
    setState(() {
      _isPaused = true;
    });
    _playTimer?.cancel();
  }

  void _resumePlaying() {
    setState(() {
      _isPaused = false;
    });
    _playCurrentMotion();
  }

  void _stopPlaying() {
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentPlayingIndex = -1;
    });
    _playTimer?.cancel();

    if (mounted) {
      showTopSnackBar(context, '動作序列已停止');
    }
  }

  void _nextMotion() {
    if (!_isPlaying || _currentPlayingIndex >= _sequence.length - 1) return;

    _playTimer?.cancel();
    setState(() {
      _currentPlayingIndex++;
    });
    _playCurrentMotion();
  }

  void _previousMotion() {
    if (!_isPlaying || _currentPlayingIndex <= 0) return;

    _playTimer?.cancel();
    setState(() {
      _currentPlayingIndex--;
    });
    _playCurrentMotion();
  }

  void _clearSequence() {
    if (_isPlaying) return; // 播放中不允許清除

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
                  setState(() {
                    _sequence.clear();
                    _durations.clear();
                  });
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
    if (_sequence.isEmpty) return;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SequenceDialog(
              sequence: _sequence,
              durations: _durations,
              isPlaying: _isPlaying,
              currentPlayingIndex: _currentPlayingIndex,
              onClearSequence: _clearSequence,
              onReorder: (oldIndex, newIndex) {
                setDialogState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _sequence.removeAt(oldIndex);
                  final duration = _durations.removeAt(oldIndex);
                  _sequence.insert(newIndex, item);
                  _durations.insert(newIndex, duration);
                });
              },
              onDurationChanged: (index, newDuration) {
                setDialogState(() {
                  _durations[index] = newDuration;
                });
              },
              onRemoveItem: (index) {
                setDialogState(() {
                  _sequence.removeAt(index);
                  _durations.removeAt(index);
                });
              },
            );
          },
        );
      },
    );
    setState(() {});
  }

  void _savePlaylist() {
    if (_isPlaying || _sequence.isEmpty) {
      if (_sequence.isEmpty) {
        showTopSnackBar(
          context,
          '播放列表為空，無法儲存',
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
            currentPlaylistId: _currentPlaylistId,
            currentPlaylistName: _currentPlaylistName,
            sequence: _sequence,
            durations: _durations,
            onSaveComplete: (id, name) {
              setState(() {
                _currentPlaylistId = id;
                _currentPlaylistName = name;
              });
            },
          ),
    );
  }

  void _loadPlaylist(MotionPlaylist playlist) {
    if (_isPlaying) return; // 播放中不允許載入

    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    setState(() {
      _sequence.clear();
      _durations.clear();
      _currentPlaylistId = playlist.id;
      _currentPlaylistName = playlist.name;
      for (final item in playlist.items) {
        final template = storageService.getTemplateById(item.templateId);
        if (template != null) {
          _sequence.add(template);
          _durations.add(item.duration);
        }
      }
    });
    showTopSnackBar(
      context,
      '已載入播放列表 "${playlist.name}"',
      backgroundColor: AppColors.blueButton(context), // 使用統一的藍色
      icon: Icons.playlist_play,
    );
  }

  void _newPlaylist() {
    if (_isPlaying) return; // 播放中不允許新增

    setState(() {
      _sequence.clear();
      _durations.clear();
      _currentPlaylistId = null;
      _currentPlaylistName = '未命名播放列表';
    });
  }

  void _showPlaylistMenu() {
    if (_isPlaying) return;

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
                '已開啟新的播放列表',
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
    _showDeleteConfirmationDialog(
      '確認刪除',
      '確定要刪除動作 "${template.name}" 嗎？',
      () async {
        try {
          await storageService.deleteTemplate(template.id);
          setState(() {
            _sequence.removeWhere((t) => t.id == template.id);
            _durations.removeWhere(
              (d) => _sequence.indexWhere((t) => t.id == template.id) == -1,
            );
          });
          showTopSnackBar(context, '動作 "${template.name}" 已刪除');
        } catch (e) {
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
    if (_isPlaying) return; // 播放中不允許顯示動作選項

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
    final isConnected = btService.connected;

    Provider.of<MotionStorageService>(context);

    return Stack(
      key: _stackKey,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              MotionLibrarySection(
                onAddToSequence: _addToSequence,
                onEditTemplate: _isPlaying ? null : widget.onEditTemplate,
                onShowActions: _showActionsForTemplate,
              ),
              const SizedBox(height: 16),
              PlaylistControlsCard(
                currentPlaylistName: _currentPlaylistName,
                sequenceLength: _sequence.length,
                isPlaying: _isPlaying,
                isConnected: isConnected,
                currentPlayingIndex: _currentPlayingIndex,
                onExecuteSequence: _executeSequence,
                onShowPlaylistMenu: _showPlaylistMenu,
                onShowSequenceDialog: _showSequenceDialog,
                onSavePlaylist: _savePlaylist,
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
