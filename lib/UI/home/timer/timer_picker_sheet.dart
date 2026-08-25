import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';


class TimerPickerSheet extends StatefulWidget {
  const TimerPickerSheet({
    super.key,
    required this.selectedMinutes,
  });
  final int selectedMinutes;

  @override
  State<TimerPickerSheet> createState() => _TimerPickerSheetState();
}

class _TimerPickerSheetState extends State<TimerPickerSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            const SizedBox(height: 20),
            _buildTitle(),
            const SizedBox(height: 24),
            HorizontalRulerPicker(
              value: _selected,
              min: 5,
              max: 480,
              step: 5,
              onChanged: (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 12), // 👈 was 28 — smaller now that there's no button below
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border(context),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Timer Setting',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Choose block time duration',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

  String _formatLabel(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }




// ── Horizontal ruler picker ───────────────────────────
class HorizontalRulerPicker extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const HorizontalRulerPicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  State<HorizontalRulerPicker> createState() => _HorizontalRulerPickerState();
}

class _HorizontalRulerPickerState extends State<HorizontalRulerPicker> {
  late FixedExtentScrollController _controller;
  late List<int> _values;
  static const _itemExtent = 16.0;

  @override
  void initState() {
    super.initState();
    _values = [for (int v = widget.min; v <= widget.max; v += widget.step) v];
    final initialIndex = _values.indexOf(widget.value).clamp(0, _values.length - 1);
    _controller = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatDuration(widget.value),
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: _FlankingLabels(value: widget.value, step: widget.step),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotatedBox(
                quarterTurns: -1,
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (notification) {
                    final index = _controller.selectedItem;
                    final newValue = _values[index.clamp(0, _values.length - 1)];
                    HapticFeedback.selectionClick();
                    widget.onChanged(newValue);
                    return false;
                  },
                  child: ListWheelScrollView.useDelegate(
                    controller: _controller,
                    itemExtent: _itemExtent,
                    physics: const FixedExtentScrollPhysics(),
                    diameterRatio: 6,
                    perspective: 0.002,
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      widget.onChanged(_values[index]);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _values.length,
                      builder: (context, index) {
                        final v = _values[index];
                        final isMajor = v % 30 == 0; // major every 30m, given the 8h range
                        return RotatedBox(
                          quarterTurns: 1,
                          child: Center(
                            child: Container(
                              width: 1.5,
                              height: isMajor ? 26 : 14,
                              color: AppColors.textSecondary(context).withValues(alpha: isMajor ? 0.5 : 0.25),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 34,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlankingLabels extends StatelessWidget {
  final int value;
  final int step;

  const _FlankingLabels({required this.value, required this.step});

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final leftLabel = value - 30;
    final rightLabel = value + 30;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(leftLabel.clamp(5, 480)),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary(context).withValues(alpha: 0.6),
          ),
        ),
        Text(
          _formatDuration(rightLabel.clamp(5, 480)),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary(context).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}