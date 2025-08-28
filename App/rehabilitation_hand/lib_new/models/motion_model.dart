enum FingerState { extended, relaxed, contracted }

class MotionTemplate {
  final String id;
  final String name;
  final List<FingerPosition> positions;
  final DateTime createdAt;

  MotionTemplate({
    required this.id,
    required this.name,
    required this.positions,
    required this.createdAt,
  });
}

class FingerPosition {
  final FingerState thumb;
  final FingerState index;
  final FingerState middle;
  final FingerState ring;
  final FingerState pinky;
  final int holdDuration; // 維持時間（秒）

  FingerPosition({
    required this.thumb,
    required this.index,
    required this.middle,
    required this.ring,
    required this.pinky,
    this.holdDuration = 1,
  });

  String toCommand() {
    // 轉換為藍牙指令格式
    return '${_stateToValue(thumb)},${_stateToValue(index)},${_stateToValue(middle)},${_stateToValue(ring)},${_stateToValue(pinky)}';
  }

  int _stateToValue(FingerState state) {
    switch (state) {
      case FingerState.extended:
        return 0;
      case FingerState.relaxed:
        return 1;
      case FingerState.contracted:
        return 2;
    }
  }
}

class MotionPlaylist {
  final String id;
  final String name;
  final List<PlaylistItem> items;
  final DateTime createdAt;

  MotionPlaylist({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });
}

class PlaylistItem {
  final String templateId;
  final int duration;

  PlaylistItem({required this.templateId, required this.duration});
}
