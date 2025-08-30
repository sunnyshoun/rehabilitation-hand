import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/services/playlist_player_service.dart';
import 'package:rehabilitation_hand/config/themes.dart';

class PlaylistPlayerBar extends StatefulWidget {
  const PlaylistPlayerBar({super.key});

  @override
  State<PlaylistPlayerBar> createState() => _PlaylistPlayerBarState();
}

class _PlaylistPlayerBarState extends State<PlaylistPlayerBar> {
  bool _isExpanded = true;
  Timer? _progressTimer;
  double _dragAccumulated = 0.0; // 累積拖曳距離，用於判斷展開/收合

  @override
  void initState() {
    super.initState();
    final playerService = Provider.of<PlaylistPlayerService>(
      context,
      listen: false,
    );
    if (playerService.isPlaying && !playerService.isPaused) {
      _startProgressTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playerService = Provider.of<PlaylistPlayerService>(context);
    if (playerService.isPlaying && !playerService.isPaused) {
      _startProgressTimer();
    } else {
      _stopProgressTimer();
    }
  }

  @override
  void dispose() {
    _stopProgressTimer();
    super.dispose();
  }

  void _startProgressTimer() {
    _stopProgressTimer();
    // 極致平滑的進度條更新 - 10ms一次
    _progressTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentPlayerService = Provider.of<PlaylistPlayerService>(
        context,
        listen: false,
      );
      if (!currentPlayerService.isPlaying || currentPlayerService.isPaused) {
        timer.cancel();
        return;
      }

      // 觸發UI重新build來更新進度顯示
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlaylistPlayerService>();

    if (!playerService.isPlaying) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.sectionBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (_) => _dragAccumulated = 0.0,
            onVerticalDragUpdate: (details) {
              _dragAccumulated += details.delta.dy;
            },
            onVerticalDragEnd: (_) {
              if (_dragAccumulated < -20 && !_isExpanded) {
                setState(() => _isExpanded = true);
              } else if (_dragAccumulated > 20 && _isExpanded) {
                setState(() => _isExpanded = false);
              }
            },
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: _buildCollapsedView(context, playerService),
                  secondChild: _buildExpandedView(context, playerService),
                  crossFadeState:
                      _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                  sizeCurve: Curves.easeInOut,
                ),
                LinearProgressIndicator(
                  value: playerService.currentProgress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 3.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedView(
    BuildContext context,
    PlaylistPlayerService playerService,
  ) {
    final currentMotion = playerService.currentMotion;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.front_hand, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${currentMotion?.name ?? '正在準備...'} (剩餘 ${playerService.remainingSeconds}s)',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(
    BuildContext context,
    PlaylistPlayerService playerService,
  ) {
    final currentMotion = playerService.currentMotion;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.front_hand, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '目前動作: ${currentMotion?.name ?? '準備中...'} (剩餘 ${playerService.remainingSeconds}s)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 右上角手 icon 已移除
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.repeat),
                color:
                    playerService.isRepeat
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                onPressed: playerService.toggleRepeat,
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: playerService.previousMotion,
              ),
              IconButton(
                icon: Icon(
                  playerService.isPaused ? Icons.play_arrow : Icons.pause,
                ),
                iconSize: 40,
                onPressed:
                    playerService.isPaused
                        ? playerService.resumePlaying
                        : playerService.pausePlaying,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: playerService.nextMotion,
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                color: Colors.red,
                onPressed: playerService.stopPlaying,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
