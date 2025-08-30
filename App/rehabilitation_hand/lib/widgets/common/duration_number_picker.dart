import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 秒數選擇器 (1~60)。自訂 ListWheelScrollView，項目顯示「X 秒」，不在下方額外顯示文字。
class DurationNumberPicker extends StatefulWidget {
  final int initial; // 初始秒數 (1~60)
  final ValueChanged<int> onChanged; // 當選擇變更時回傳新值

  const DurationNumberPicker({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<DurationNumberPicker> createState() => _DurationNumberPickerState();
}

class _DurationNumberPickerState extends State<DurationNumberPicker> {
  static const _min = 1;
  static const _max = 60;
  static const _itemExtent = 50.0;
  late int _value;
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.initial.clamp(_min, _max);
    _controller = FixedExtentScrollController(initialItem: _value - _min);
  }

  @override
  void didUpdateWidget(covariant DurationNumberPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _value = widget.initial.clamp(_min, _max);
      _controller.jumpToItem(_value - _min);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          NotificationListener<ScrollEndNotification>(
            onNotification: (n) {
              _snapIfNeeded();
              return false;
            },
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: _itemExtent,
              physics: const _SmoothSnapScrollPhysics(),
              perspective: 0.005,
              diameterRatio: 1.2,
              onSelectedItemChanged: (i) {
                final newVal = i + _min;
                if (newVal != _value) {
                  setState(() => _value = newVal);
                  HapticFeedback.selectionClick();
                  widget.onChanged(newVal);
                }
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _max - _min + 1,
                builder: (context, index) {
                  final v = index + _min;
                  final selected = v == _value;
                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: selected ? 24 : 18,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color:
                          selected ? primary : theme.textTheme.bodyLarge?.color,
                    ),
                    child: Center(child: Text('$v 秒')),
                  );
                },
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              height: _itemExtent,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary.withOpacity(.3), width: 2),
                  bottom: BorderSide(color: primary.withOpacity(.3), width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snapIfNeeded() {
    if (!_controller.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _align());
  }

  void _align() {
    if (!_controller.hasClients) return;
    final offset = _controller.offset;
    final raw = offset / _itemExtent;
    final targetIndex = raw.round();
    final targetOffset = targetIndex * _itemExtent;
    final diff = (targetOffset - offset).abs();
    if (diff < 0.5) return;
    _controller.animateTo(
      targetOffset,
      duration: Duration(
        milliseconds: (120 + diff * 4).clamp(120, 260).toInt(),
      ),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// 自訂物理：延長慣性、最後仍吸附最近 item。
class _SmoothSnapScrollPhysics extends FixedExtentScrollPhysics {
  const _SmoothSnapScrollPhysics({ScrollPhysics? parent})
    : super(parent: parent);

  @override
  _SmoothSnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SmoothSnapScrollPhysics(parent: buildParent(ancestor));

  static const double _deceleration = 0.0009; // 調整慣性 (越小越滑)

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position is! FixedExtentMetrics)
      return super.createBallisticSimulation(position, velocity);
    if (velocity.abs() < tolerance.velocity)
      return super.createBallisticSimulation(position, velocity);
    final metrics = position;
    // 某些 Flutter 版本 FixedExtentMetrics 未公開 itemExtent，改用我們自訂的固定高度
    const itemExtent = _DurationNumberPickerState._itemExtent;
    // 粗估最終位移 (簡化版 v^2 / 2a)
    final distance =
        (velocity * velocity) / (2 / _deceleration) * velocity.sign;
    double projected = metrics.pixels + distance;
    projected = projected.clamp(
      metrics.minScrollExtent,
      metrics.maxScrollExtent,
    );
    final targetIndex = (projected / itemExtent).round();
    final targetPixels = (targetIndex * itemExtent).clamp(
      metrics.minScrollExtent,
      metrics.maxScrollExtent,
    );
    return ScrollSpringSimulation(
      spring,
      metrics.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }
}
