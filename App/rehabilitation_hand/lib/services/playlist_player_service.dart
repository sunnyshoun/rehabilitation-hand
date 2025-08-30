import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rehabilitation_hand/models/motion_model.dart';
import 'package:rehabilitation_hand/services/bluetooth_service.dart';
import 'package:rehabilitation_hand/services/motion_storage_service.dart';

class PlaylistPlayerService with ChangeNotifier {
  final BluetoothService _bluetoothService;
  final MotionStorageService _motionStorageService;

  List<MotionTemplate> _sequence = [];
  List<int> _durations = [];
  bool _isPlaying = false;
  bool _isPaused = false;
  int _currentPlayingIndex = -1;
  Timer? _playTimer;
  String? _currentPlaylistId;
  String _currentPlaylistName = '未命名動作列表';
  bool _isRepeat = false;

  // 剩餘時間和經過時間
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  // 暫停時精準保存的已經過秒數(含小數)，避免進度條回退至整秒
  double _pausedExactElapsedSeconds = 0.0;
  // 暫停期間是否切換了動作（上一個/下一個/跳轉）
  bool _motionChangedWhilePaused = false;
  DateTime? _motionStartTime;
  DateTime? _pauseStartTime;
  int _totalPausedDuration = 0;
  Timer? _countdownTimer;

  PlaylistPlayerService(this._bluetoothService, this._motionStorageService) {
    _motionStorageService.addListener(_onStorageChanged);
  }

  void _onStorageChanged() {
    // Update the sequence to reflect changes in templates
    final updatedSequence = <MotionTemplate>[];
    final updatedDurations = <int>[];

    for (int i = 0; i < _sequence.length; i++) {
      final currentTemplate = _sequence[i];
      final updatedTemplate = _motionStorageService.getTemplateById(
        currentTemplate.id,
      );
      if (updatedTemplate != null) {
        updatedSequence.add(updatedTemplate);
        updatedDurations.add(_durations[i]);
      }
      // If template is deleted, skip it
    }

    _sequence = updatedSequence;
    _durations = updatedDurations;

    // If current playing index is out of bounds, stop playing
    if (_currentPlayingIndex >= _sequence.length) {
      stopPlaying();
    }

    // 保持當前動作列表的信息，不要重置為未命名動作列表
    // 只有在序列完全為空且沒有當前動作列表ID時才重置
    if (_sequence.isEmpty && _currentPlaylistId == null) {
      _currentPlaylistName = '未命名動作列表';
    }

    notifyListeners();
  }

  // Getters
  List<MotionTemplate> get sequence => _sequence;
  List<int> get durations => _durations;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  int get currentPlayingIndex => _currentPlayingIndex;
  String? get currentPlaylistId => _currentPlaylistId;
  String get currentPlaylistName => _currentPlaylistName;
  bool get isRepeat => _isRepeat;
  int get remainingSeconds => _remainingSeconds;
  int get elapsedSeconds => _elapsedSeconds;

  // 計算當前動作的進度 (0.0 to 1.0)
  double get currentProgress {
    if (_currentPlayingIndex == -1 ||
        _currentPlayingIndex >= _durations.length ||
        _motionStartTime == null) {
      return 0.0;
    }
    final totalDuration = _durations[_currentPlayingIndex];
    if (totalDuration <= 0) return 0.0;
    // 暫停時固定回傳暫停當下的進度，避免暫停期間時間流逝造成跳動
    if (_isPaused) {
      return (_pausedExactElapsedSeconds / totalDuration).clamp(0.0, 1.0);
    }

    // 使用實時計算確保最平滑的進度 (播放中)
    final now = DateTime.now();
    final totalElapsed =
        now.difference(_motionStartTime!).inMilliseconds -
        _totalPausedDuration; // _totalPausedDuration 已含暫停累積
    final elapsedInSeconds = (totalElapsed / 1000).clamp(
      0,
      totalDuration.toDouble(),
    );

    return (elapsedInSeconds / totalDuration).clamp(0.0, 1.0);
  }

  MotionTemplate? get currentMotion =>
      _currentPlayingIndex != -1 && _currentPlayingIndex < _sequence.length
          ? _sequence[_currentPlayingIndex]
          : null;

  int? get currentDuration =>
      _currentPlayingIndex != -1 && _currentPlayingIndex < _durations.length
          ? _durations[_currentPlayingIndex]
          : null;

  void addToSequence(MotionTemplate template) {
    if (_isPlaying) return;
    _sequence.add(template);
    _durations.add(2); // Default duration
    notifyListeners();
  }

  Future<void> executeSequence() async {
    if (!_bluetoothService.connected) {
      // Optionally, handle not connected case, e.g., show a message
      return;
    }
    _isPlaying = true;
    _isPaused = false;
    _currentPlayingIndex = 0;
    notifyListeners();
    await _playCurrentMotion();
  }

  Future<void> _playCurrentMotion() async {
    if (!_isPlaying || _isPaused) return;

    if (_currentPlayingIndex >= _sequence.length) {
      if (_isRepeat) {
        _currentPlayingIndex = 0;
      } else {
        stopPlaying();
        return;
      }
    }

    final template = _sequence[_currentPlayingIndex];
    if (template.positions.isNotEmpty) {
      final position = template.positions.first;

      // 重置時間追蹤
      _motionStartTime = DateTime.now();
      _totalPausedDuration = 0;
      _elapsedSeconds = 0;
      _startCountdown(_durations[_currentPlayingIndex]);

      notifyListeners(); // 立即更新UI

      await _bluetoothService.sendFingerPosition(position);

      _playTimer?.cancel();
      _playTimer = Timer(
        Duration(seconds: _durations[_currentPlayingIndex]),
        () {
          if (_isPlaying && !_isPaused) {
            _currentPlayingIndex++;
            _playCurrentMotion();
          }
        },
      );
    }
  }

  void _startCountdown(int totalSeconds) {
    _countdownTimer?.cancel();
    _remainingSeconds = totalSeconds - _elapsedSeconds;
    notifyListeners();

    // 高頻率更新確保時間顯示平滑
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_motionStartTime != null && !_isPaused) {
        final now = DateTime.now();
        final totalElapsed =
            now.difference(_motionStartTime!).inMilliseconds -
            _totalPausedDuration;
        final elapsedInSeconds = (totalElapsed / 1000);

        _elapsedSeconds =
            elapsedInSeconds.clamp(0, totalSeconds.toDouble()).toInt();
        _remainingSeconds = (totalSeconds - _elapsedSeconds).clamp(
          0,
          totalSeconds,
        );

        notifyListeners();

        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      }
    });
  }

  void pausePlaying() {
    _isPaused = true;
    _pauseStartTime = DateTime.now();
    // 計算當前精準已經過秒數（含小數）
    if (_motionStartTime != null) {
      final now = DateTime.now();
      final totalElapsedMs =
          now.difference(_motionStartTime!).inMilliseconds -
          _totalPausedDuration;
      final totalDuration =
          _durations.isNotEmpty &&
                  _currentPlayingIndex >= 0 &&
                  _currentPlayingIndex < _durations.length
              ? _durations[_currentPlayingIndex]
              : 0;
      _pausedExactElapsedSeconds = (totalElapsedMs / 1000.0).clamp(
        0,
        totalDuration.toDouble(),
      );
    }
    _playTimer?.cancel();
    _countdownTimer?.cancel();
    _motionChangedWhilePaused = false; // 進入暫停時重置
    notifyListeners();
  }

  void resumePlaying() {
    if (!_isPaused) return;

    _isPaused = false;
    _pausedExactElapsedSeconds = 0.0; // 清除暫停快照

    // 計算暫停期間的時長
    if (_pauseStartTime != null) {
      final pauseDuration =
          DateTime.now().difference(_pauseStartTime!).inMilliseconds;
      _totalPausedDuration += pauseDuration;
      _pauseStartTime = null;
    }

    if (_motionChangedWhilePaused) {
      // 若暫停時有切換動作，恢復時重新播放該新動作（從0開始）
      _motionChangedWhilePaused = false;
      _playCurrentMotion();
    } else {
      // 繼續倒數和播放，但不重新開始動作
      final remainingDuration = _remainingSeconds;
      if (remainingDuration > 0) {
        _startCountdown(_durations[_currentPlayingIndex]);

        _playTimer?.cancel();
        _playTimer = Timer(Duration(seconds: remainingDuration), () {
          if (_isPlaying && !_isPaused) {
            _currentPlayingIndex++;
            _playCurrentMotion();
          }
        });
      }
    }

    notifyListeners();
  }

  void stopPlaying() {
    _isPlaying = false;
    _isPaused = false;
    _currentPlayingIndex = -1;
    _playTimer?.cancel();
    _countdownTimer?.cancel();
    _remainingSeconds = 0;
    _elapsedSeconds = 0;
    _pausedExactElapsedSeconds = 0.0;
    _motionStartTime = null;
    _pauseStartTime = null;
    _totalPausedDuration = 0;
    notifyListeners();
  }

  void nextMotion() {
    if (!_isPlaying || _currentPlayingIndex >= _sequence.length - 1) return;
    _playTimer?.cancel();
    _countdownTimer?.cancel();
    _currentPlayingIndex++;
    if (_isPaused) {
      // 在暫停狀態下切換動作，重置時間顯示但保持暫停
      _motionStartTime = DateTime.now();
      _totalPausedDuration = 0;
      _elapsedSeconds = 0;
      _remainingSeconds = _durations[_currentPlayingIndex];
      _pausedExactElapsedSeconds = 0.0;
      _motionChangedWhilePaused = true;
      notifyListeners();
    } else {
      _playCurrentMotion();
    }
  }

  void previousMotion() {
    if (!_isPlaying || _currentPlayingIndex <= 0) return;
    _playTimer?.cancel();
    _countdownTimer?.cancel();
    _currentPlayingIndex--;
    if (_isPaused) {
      _motionStartTime = DateTime.now();
      _totalPausedDuration = 0;
      _elapsedSeconds = 0;
      _remainingSeconds = _durations[_currentPlayingIndex];
      _pausedExactElapsedSeconds = 0.0;
      _motionChangedWhilePaused = true;
      notifyListeners();
    } else {
      _playCurrentMotion();
    }
  }

  void jumpToMotion(int index) {
    if (!_isPlaying || index < 0 || index >= _sequence.length) return;
    _playTimer?.cancel();
    _countdownTimer?.cancel();
    _currentPlayingIndex = index;
    if (_isPaused) {
      _motionStartTime = DateTime.now();
      _totalPausedDuration = 0;
      _elapsedSeconds = 0;
      _remainingSeconds = _durations[_currentPlayingIndex];
      _pausedExactElapsedSeconds = 0.0;
      _motionChangedWhilePaused = true;
      notifyListeners();
    } else {
      _playCurrentMotion();
    }
  }

  void clearSequence() {
    if (_isPlaying) return;
    _sequence.clear();
    _durations.clear();

    // 只有在沒有當前動作列表ID時才重置名稱
    if (_currentPlaylistId == null) {
      _currentPlaylistName = '未命名動作列表';
    }

    notifyListeners();
  }

  void reorderSequence(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _sequence.removeAt(oldIndex);
    final duration = _durations.removeAt(oldIndex);
    _sequence.insert(newIndex, item);
    _durations.insert(newIndex, duration);
    notifyListeners();
  }

  void updateDuration(int index, int newDuration) {
    _durations[index] = newDuration;
    notifyListeners();
  }

  void removeSequenceItem(int index) {
    _sequence.removeAt(index);
    _durations.removeAt(index);
    notifyListeners();
  }

  void loadPlaylist(MotionPlaylist playlist) {
    if (_isPlaying) return;
    _sequence.clear();
    _durations.clear();
    _currentPlaylistId = playlist.id;
    _currentPlaylistName = playlist.name;
    for (final item in playlist.items) {
      final template = _motionStorageService.getTemplateById(item.templateId);
      if (template != null) {
        _sequence.add(template);
        _durations.add(item.duration);
      }
    }
    notifyListeners();
  }

  void newPlaylist() {
    if (_isPlaying) return;
    _sequence.clear();
    _durations.clear();
    _currentPlaylistId = null;
    _currentPlaylistName = '未命名動作列表';
    notifyListeners();
  }

  void setPlaylistInfo(String id, String name) {
    _currentPlaylistId = id;
    _currentPlaylistName = name;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  @override
  void dispose() {
    _motionStorageService.removeListener(_onStorageChanged);
    _playTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
