import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/services/bluetooth_service.dart';
import 'package:rehabilitation_hand/services/motion_storage_service.dart';
import 'package:rehabilitation_hand/widgets/common/top_snackbar.dart';
import 'package:rehabilitation_hand/widgets/motion/motion_library.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/config/constants.dart';

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
      backgroundColor: AppColors.getBlueButtonColor(context), // 使用統一的藍色
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
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('序列內容'),
                  if (!_isPlaying)
                    CommonButton(
                      label: '清除全部',
                      onPressed: () {
                        Navigator.pop(context);
                        _clearSequence();
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
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 400,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.getCardBackground(context), // 使用卡片背景顏色
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('總共 ${_sequence.length} 個動作'),
                          Text(
                            '總時長: ${_durations.fold(0, (sum, d) => sum + d)} 秒',
                          ),
                        ],
                      ),
                    ),
                    if (_isPlaying)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.getSectionBackground(context) // 深色模式使用 section 背景（800）
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
                              '正在播放: ${_currentPlayingIndex + 1} / ${_sequence.length}',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
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
                          _sequence.isEmpty
                              ? const Center(child: Text('序列已清空'))
                              : _isPlaying
                              ? ListView.builder(
                                itemCount: _sequence.length,
                                itemBuilder: (context, index) {
                                  final template = _sequence[index];
                                  final isCurrentPlaying =
                                      index == _currentPlayingIndex;
                                  return Card(
                                    color:
                                        isCurrentPlaying
                                            ? (Theme.of(context).brightness == Brightness.dark
                                                ? Colors.green.shade700.withOpacity(0.6) // 使用 700 系列的綠色
                                                : Colors.green.shade100)
                                            : AppColors.getCardBackground(context), // 普通卡片使用卡片背景（700）
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            isCurrentPlaying
                                                ? Colors.green
                                                : null,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color:
                                                isCurrentPlaying
                                                    ? Colors.white
                                                    : null,
                                          ),
                                        ),
                                      ),
                                      title: Text(template.name),
                                      subtitle: Text(
                                        '持續: ${_durations[index]} 秒',
                                      ),
                                      trailing:
                                          isCurrentPlaying
                                              ? const Icon(
                                                Icons.play_arrow,
                                                color: Colors.green,
                                              )
                                              : null,
                                    ),
                                  );
                                },
                              )
                              : ReorderableListView.builder(
                                itemCount: _sequence.length,
                                itemBuilder: (context, index) {
                                  final template = _sequence[index];
                                  return Card(
                                    key: ValueKey(
                                      template.id + index.toString(),
                                    ),
                                    color: AppColors.getCardBackground(context), // 設置卡片背景
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text('${index + 1}'),
                                      ),
                                      title: Text(template.name),
                                      subtitle: Row(
                                        children: [
                                          const Text('持續: '),
                                          DropdownButton<int>(
                                            value: _durations[index],
                                            items:
                                                List.generate(10, (i) => i + 1)
                                                    .map(
                                                      (sec) => DropdownMenuItem(
                                                        value: sec,
                                                        child: Text('$sec 秒'),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged: (value) {
                                              if (value != null) {
                                                setDialogState(
                                                  () =>
                                                      _durations[index] = value,
                                                );
                                              }
                                            },
                                            underline: Container(),
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            _sequence.removeAt(index);
                                            _durations.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                                onReorder: (oldIndex, newIndex) {
                                  setDialogState(() {
                                    if (newIndex > oldIndex) newIndex -= 1;
                                    final item = _sequence.removeAt(oldIndex);
                                    final duration = _durations.removeAt(
                                      oldIndex,
                                    );
                                    _sequence.insert(newIndex, item);
                                    _durations.insert(newIndex, duration);
                                  });
                                },
                              ),
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
                  color: AppColors.getBlueButtonColor(context), // 使用統一的藍色
                  textColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
  }

  void _savePlaylist() {
    if (_isPlaying) return; // 播放中不允許儲存

    if (_sequence.isEmpty) {
      showTopSnackBar(
        context,
        '播放列表為空，無法儲存',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (context) {
        String tempName =
            _currentPlaylistName == '未命名播放列表' ? '' : _currentPlaylistName;
        String? errorText;
        final nameController = TextEditingController(text: tempName);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_currentPlaylistId != null ? '更新播放列表' : '儲存播放列表'),
              content: TextField(
                autofocus: true,
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '播放列表名稱',
                  floatingLabelBehavior:
                      FloatingLabelBehavior.always, // 標籤永遠浮在外框上
                  labelStyle: TextStyle(color: Colors.blue), // 標籤顏色
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  errorText: errorText,
                ),
                onChanged: (value) {
                  tempName = value;
                  if (value.isNotEmpty) {
                    final isDuplicate = storageService.isPlaylistNameTaken(
                      value,
                      excludeId: _currentPlaylistId,
                    );
                    setDialogState(
                      () => errorText = isDuplicate ? '此名稱已存在' : null,
                    );
                  } else {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                CommonButton(
                  label: _currentPlaylistId != null ? '更新' : '儲存',
                  onPressed:
                      (tempName.isEmpty || errorText != null)
                          ? null
                          : () async {
                            try {
                              final items = <PlaylistItem>[];
                              for (int i = 0; i < _sequence.length; i++) {
                                items.add(
                                  PlaylistItem(
                                    templateId: _sequence[i].id,
                                    duration:
                                        i < _durations.length
                                            ? _durations[i]
                                            : 2,
                                  ),
                                );
                              }
                              final playlist = MotionPlaylist(
                                id:
                                    _currentPlaylistId ??
                                    'playlist_${DateTime.now().millisecondsSinceEpoch}',
                                name: tempName,
                                items: items,
                                createdAt: DateTime.now(),
                              );
                              await storageService.savePlaylist(playlist);
                              setState(() {
                                _currentPlaylistId = playlist.id;
                                _currentPlaylistName = tempName;
                              });
                              Navigator.pop(context);
                              showTopSnackBar(context, '播放列表 "$tempName" 已儲存');
                            } catch (e) {
                              Navigator.pop(context);
                              showTopSnackBar(
                                context,
                                '儲存失敗: $e',
                                backgroundColor: Colors.red,
                                icon: Icons.error_outline,
                              );
                            }
                          },
                  type: CommonButtonType.solid,
                  shape: CommonButtonShape.capsule,
                  color: AppColors.getBlueButtonColor(context), // 使用統一的藍色
                  textColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                ),
              ],
            );
          },
        );
      },
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
      backgroundColor: AppColors.getBlueButtonColor(context), // 使用統一的藍色
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
    if (_isPlaying) return; // 播放中不允許管理

    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    List<MotionPlaylist> playlists = List.from(storageService.playlists);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                            _newPlaylist();
                            showTopSnackBar(
                              context,
                              '已開啟新的播放列表',
                              icon: Icons.add_circle,
                              backgroundColor: AppColors.getBlueButtonColor(context), // 使用統一的藍色
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('新增播放列表'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            playlists.isEmpty
                                ? const Center(
                                  child: Text(
                                    '沒有已儲存的播放列表',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                                : ReorderableListView.builder(
                                  scrollController: scrollController,
                                  itemCount: playlists.length,
                                  itemBuilder: (context, index) {
                                    final playlist = playlists[index];
                                    // 取得目前所有存在的模板
                                    final storageService =
                                        Provider.of<MotionStorageService>(
                                          context,
                                          listen: false,
                                        );
                                    final validCount =
                                        playlist.items
                                            .where(
                                              (item) =>
                                                  storageService
                                                      .getTemplateById(
                                                        item.templateId,
                                                      ) !=
                                                  null,
                                            )
                                            .length;

                                    return Card(
                                      key: ValueKey(playlist.id),
                                      color: AppColors.getCardBackground(context), // 設置卡片背景
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
                                          onPressed: () {
                                            _showDeletePlaylistConfirmation(
                                              playlist,
                                              storageService,
                                              () {
                                                setModalState(
                                                  () => playlists.removeWhere(
                                                    (p) => p.id == playlist.id,
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          _loadPlaylist(playlist);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    );
                                  },
                                  onReorder: (oldIndex, newIndex) async {
                                    setModalState(() {
                                      if (newIndex > oldIndex) newIndex -= 1;
                                      final item = playlists.removeAt(oldIndex);
                                      playlists.insert(newIndex, item);
                                    });
                                    try {
                                      await storageService.saveAllPlaylists(
                                        playlists,
                                      );
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
          },
        );
      },
    );
  }

  void _showDeletePlaylistConfirmation(
    MotionPlaylist playlist,
    MotionStorageService storageService, [
    VoidCallback? onDeleted,
  ]) async {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await storageService.deletePlaylist(playlist.id);
        if (_currentPlaylistId == playlist.id) _newPlaylist();
        showTopSnackBar(context, '播放列表 "${playlist.name}" 已刪除');
        onDeleted?.call();
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

  void _deleteTemplate(
    MotionTemplate template,
    MotionStorageService storageService,
  ) async {
    if (_isPlaying) return; // 播放中不允許刪除

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('確認刪除'),
            content: Text('確定要刪除動作 "${template.name}" 嗎？'),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      try {
        await storageService.deleteTemplate(template.id);

        // 從序列中移除被刪除的動作
        setState(() {
          final indicesToRemove = <int>[];
          for (int i = _sequence.length - 1; i >= 0; i--) {
            if (_sequence[i].id == template.id) {
              indicesToRemove.add(i);
            }
          }
          for (final index in indicesToRemove) {
            _sequence.removeAt(index);
            _durations.removeAt(index);
          }
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
    }
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

  Widget _buildHighlightOverlay() {
    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );

    return IgnorePointer(
      ignoring: !_isOverlayVisible && _highlightedTemplate == null,
      child: AnimatedOpacity(
        opacity: _isOverlayVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideActions,
                child: Container(color: Colors.black.withAlpha(153)),
              ),
            ),
            if (_highlightedTemplate != null &&
                _highlightedTemplateRect != null) ...[
              Positioned(
                top: _highlightedTemplateRect!.top,
                left: _highlightedTemplateRect!.left,
                width: _highlightedTemplateRect!.width,
                height: _highlightedTemplateRect!.height,
                child: IgnorePointer(
                  child: TemplateCard(
                    template: _highlightedTemplate!,
                    isCustom: true,
                    isHighlighted: true,
                  ),
                ),
              ),
              Positioned(
                top: _highlightedTemplateRect!.top - 10,
                left: _highlightedTemplateRect!.right - 75,
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
                          final templateId = _highlightedTemplate!.id;
                          _hideActions();
                          widget.onEditTemplate?.call(templateId);
                        },
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        onTap: () {
                          final template = _highlightedTemplate!;
                          _hideActions();
                          _deleteTemplate(template, storageService);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final btService = Provider.of<BluetoothService>(context);
    final isConnected = btService.connected;

    // 監聽 storage service 的變化
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
                onEditTemplate:
                    _isPlaying ? null : widget.onEditTemplate, // 播放中禁用編輯
                onDeleteTemplate: _deleteTemplate,
                onShowActions: _showActionsForTemplate,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.playlist_play, size: 28),
                      title: const Text(
                        '播放列表',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: CommonButton(
                        label: '播放',
                        icon: Icons.play_arrow,
                        onPressed:
                            (isConnected && _sequence.isNotEmpty)
                                ? _executeSequence
                                : null,
                        type: CommonButtonType.solid,
                        shape: CommonButtonShape.capsule,
                        color:
                            (isConnected && _sequence.isNotEmpty)
                                ? Colors.green
                                : Colors.grey.shade300,
                        textColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.getSectionBackground(context), // 保持 section 背景相對淺色
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 16,
                              color: AppColors.getInfoTextColor(context), // 使用主題顏色
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentPlaylistName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.getInfoTextColor(context), // 使用主題顏色
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isPlaying && _sequence.isNotEmpty)
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
                                  '${_currentPlayingIndex + 1}/${_sequence.length}',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '序列項目: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.getButtonColor(context, Colors.deepPurple),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_sequence.length}',
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
                              onPressed: _isPlaying ? null : _showPlaylistMenu,
                              type: CommonButtonType.outline,
                              shape: CommonButtonShape.capsule,
                              color: AppColors.getButtonColor(context, Colors.deepPurple),
                              textColor: AppColors.getButtonColor(context, Colors.deepPurple),
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
                                  _sequence.isEmpty
                                      ? null
                                      : _showSequenceDialog,
                              type: CommonButtonType.outline,
                              shape: CommonButtonShape.capsule,
                              color:
                                  _sequence.isEmpty 
                                      ? Colors.grey 
                                      : AppColors.getBlueButtonColor(context), // 使用統一的藍色
                              textColor:
                                  _sequence.isEmpty 
                                      ? Colors.grey 
                                      : AppColors.getBlueButtonColor(context),
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
                                  _sequence.isEmpty ? null : _savePlaylist,
                              type: CommonButtonType.outline,
                              shape: CommonButtonShape.capsule,
                              color:
                                  _sequence.isEmpty 
                                      ? Colors.grey 
                                      : AppColors.getBlueButtonColor(context), // 使用統一的藍色
                              textColor:
                                  _sequence.isEmpty 
                                      ? Colors.grey 
                                      : AppColors.getBlueButtonColor(context),
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
              ),
            ],
          ),
        ),
        _buildHighlightOverlay(),
      ],
    );
  }
}

// ====== Reusable Action Button for Overlay ======
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