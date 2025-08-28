import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/services/motion_storage_service.dart';
import 'package:rehabilitation_hand/widgets/common/common_button.dart';
import 'package:rehabilitation_hand/widgets/common/top_snackbar.dart';

class SavePlaylistDialog extends StatefulWidget {
  final String? currentPlaylistId;
  final String currentPlaylistName;
  final List<MotionTemplate> sequence;
  final List<int> durations;
  final Function(String, String) onSaveComplete;

  const SavePlaylistDialog({
    super.key,
    this.currentPlaylistId,
    required this.currentPlaylistName,
    required this.sequence,
    required this.durations,
    required this.onSaveComplete,
  });

  @override
  State<SavePlaylistDialog> createState() => _SavePlaylistDialogState();
}

class _SavePlaylistDialogState extends State<SavePlaylistDialog> {
  late String _tempName;
  String? _errorText;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _tempName =
        widget.currentPlaylistName == '未命名播放列表'
            ? ''
            : widget.currentPlaylistName;
    _nameController = TextEditingController(text: _tempName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateName(String value) {
    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    setState(() {
      _tempName = value;
      if (value.isNotEmpty) {
        final isDuplicate = storageService.isPlaylistNameTaken(
          value,
          excludeId: widget.currentPlaylistId,
        );
        _errorText = isDuplicate ? '此名稱已存在' : null;
      } else {
        _errorText = null;
      }
    });
  }

  Future<void> _onSave() async {
    if (_tempName.isEmpty || _errorText != null) return;

    final storageService = Provider.of<MotionStorageService>(
      context,
      listen: false,
    );
    try {
      final items = <PlaylistItem>[];
      for (int i = 0; i < widget.sequence.length; i++) {
        items.add(
          PlaylistItem(
            templateId: widget.sequence[i].id,
            duration: i < widget.durations.length ? widget.durations[i] : 2,
          ),
        );
      }
      final playlist = MotionPlaylist(
        id:
            widget.currentPlaylistId ??
            'playlist_${DateTime.now().millisecondsSinceEpoch}',
        name: _tempName,
        items: items,
        createdAt: DateTime.now(),
      );
      await storageService.savePlaylist(playlist);

      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(context, '播放列表 "$_tempName" 已儲存');
      }
      widget.onSaveComplete(playlist.id, _tempName);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showTopSnackBar(
          context,
          '儲存失敗: $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sectionBackground(context),
      title: Text(widget.currentPlaylistId != null ? '更新播放列表' : '儲存播放列表'),
      content: TextField(
        autofocus: true,
        controller: _nameController,
        decoration: InputDecoration(
          labelText: '播放列表名稱',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(color: Colors.blue),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          errorText: _errorText,
        ),
        onChanged: _validateName,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        CommonButton(
          label: widget.currentPlaylistId != null ? '更新' : '儲存',
          onPressed: _onSave,
          type: CommonButtonType.solid,
          shape: CommonButtonShape.capsule,
          color: AppColors.blueButton(context),
          textColor: Colors.white,
        ),
      ],
    );
  }
}
