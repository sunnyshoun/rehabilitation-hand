import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/motion_model.dart';
import '../services/bluetooth_service.dart';
import '../services/motion_storage_service.dart';
import 'top_snackbar.dart';
import 'motion_library.dart'; // Import the new library widget

class MotionTemplatesTab extends StatefulWidget {
  final Function(String)? onEditTemplate;

  const MotionTemplatesTab({super.key, this.onEditTemplate});

  @override
  State<MotionTemplatesTab> createState() => _MotionTemplatesTabState();
}

class _MotionTemplatesTabState extends State<MotionTemplatesTab> {
  // Key to get the position of the Stack that contains the overlay
  final GlobalKey _stackKey = GlobalKey();

  // Sequence and playlist state
  final List<MotionTemplate> _sequence = [];
  final List<int> _durations = [];
  bool _isPlaying = false;
  String? _currentPlaylistId;
  String _currentPlaylistName = '未命名播放列表';

  // State for the highlight overlay
  MotionTemplate? _highlightedTemplate;
  Rect? _highlightedTemplateRect;
  bool _isOverlayVisible = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _addToSequence(MotionTemplate template) {
    setState(() {
      _sequence.add(template);
      _durations.add(2); // Default duration
    });
    showTopSnackBar(
      context,
      '"${template.name}" 已加入序列',
      backgroundColor: Colors.blue,
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
    });

    for (int i = 0; i < _sequence.length; i++) {
      if (!_isPlaying) break;

      final template = _sequence[i];
      if (template.positions.isNotEmpty) {
        final position = template.positions.first;
        await btService.sendFingerPosition(position);
        await Future.delayed(Duration(seconds: _durations[i]));
      }
    }

    setState(() {
      _isPlaying = false;
    });

    if (mounted) {
      showTopSnackBar(context, '動作序列執行完成');
    }
  }

  void _stopPlaying() {
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _showSequenceDialog() async {
    if (_sequence.isEmpty) return;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('序列內容'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 400,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
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
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          _sequence.isEmpty
                              ? const Center(child: Text('序列已清空'))
                              : ReorderableListView.builder(
                                itemCount: _sequence.length,
                                itemBuilder: (context, index) {
                                  final template = _sequence[index];
                                  return Card(
                                    key: ValueKey(
                                      template.id + index.toString(),
                                    ),
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
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('完成'),
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
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '播放列表名稱',
                  border: const OutlineInputBorder(),
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
                ElevatedButton(
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
                  child: Text(_currentPlaylistId != null ? '更新' : '儲存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _loadPlaylist(MotionPlaylist playlist) {
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
      backgroundColor: Colors.blue,
      icon: Icons.playlist_play,
    );
  }

  void _newPlaylist() {
    setState(() {
      _sequence.clear();
      _durations.clear();
      _currentPlaylistId = null;
      _currentPlaylistName = '未命名播放列表';
    });
  }

  void _showPlaylistMenu() {
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
                              backgroundColor: Colors.blue,
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
                                    return Card(
                                      key: ValueKey(playlist.id),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      child: ListTile(
                                        title: Text(playlist.name),
                                        subtitle: Text(
                                          '${playlist.items.length} 個動作',
                                        ),
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('刪除', style: TextStyle(color: Colors.white)),
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('刪除', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
    if (confirm == true) {
      try {
        await storageService.deleteTemplate(template.id);
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
                child: Container(
                  color: Colors.black.withAlpha(153),
                ), // Replaced withOpacity
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
    final btService = Provider.of<BluetoothService>(context);
    final isConnected = btService.connected;

    return Stack(
      key: _stackKey,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              MotionLibrarySection(
                onAddToSequence: _addToSequence,
                onEditTemplate: widget.onEditTemplate,
                onDeleteTemplate: _deleteTemplate,
                onShowActions: _showActionsForTemplate,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.playlist_play, size: 28),
                      title: Text(
                        '播放列表',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.folder_open,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentPlaylistName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                              color: Colors.deepPurple,
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
                            if (_isPlaying)
                              ElevatedButton.icon(
                                onPressed: _stopPlaying,
                                icon: const Icon(Icons.stop, size: 16),
                                label: const Text('停止'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed:
                                    _sequence.isEmpty || !isConnected
                                        ? null
                                        : _executeSequence,
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('播放'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isConnected ? Colors.green : null,
                                  foregroundColor:
                                      isConnected ? Colors.white : null,
                                ),
                              ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed:
                                  _sequence.isEmpty ? null : _savePlaylist,
                              icon: const Icon(Icons.save, size: 16),
                              label: const Text('儲存'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _showPlaylistMenu,
                              icon: const Icon(Icons.folder_open, size: 16),
                              label: const Text('管理'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed:
                                  _sequence.isEmpty
                                      ? null
                                      : _showSequenceDialog,
                              icon: const Icon(Icons.list_alt, size: 16),
                              label: const Text('序列內容'),
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
