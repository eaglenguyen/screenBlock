import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../paywall/feature_paywall_screen.dart';
import '../../../providers/premium_provider.dart';
import '../../../services/notification_service.dart';

// ── Pomodoro config ──────────────────────────────────────────────────────────
class PomodoroConfig {
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final bool isPomodoroMode;
  const PomodoroConfig({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 30,
    this.isPomodoroMode = false,
  });
  PomodoroConfig copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    bool? isPomodoroMode,
  }) {
    return PomodoroConfig(
      workMinutes: workMinutes ?? this.workMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      isPomodoroMode: isPomodoroMode ?? this.isPomodoroMode,
    );
  }
}

// ── Duration formatter ────────────────────────────────
String formatDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

// ── Pomodoro sheet ───────────────────────────────────────────────────────────
class PomodoroSheet extends ConsumerStatefulWidget {
  final PomodoroConfig config;
  final ValueChanged<PomodoroConfig> onSave;
  const PomodoroSheet({
    super.key,
    required this.config,
    required this.onSave,
  });
  static void show(
      BuildContext context, {
        required PomodoroConfig config,
        required ValueChanged<PomodoroConfig> onSave,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => PomodoroSheet(config: config, onSave: onSave),
    );
  }
  @override
  ConsumerState<PomodoroSheet> createState() => _PomodoroSheetState();
}

class _PomodoroSheetState extends ConsumerState<PomodoroSheet> {
  late int _workMinutes;
  late int _shortBreakMinutes;
  late int _longBreakMinutes;
  late bool _isPomodoroMode;
  String? _expandedRow; // 👈 new — null means none expanded; otherwise 'work' / 'rest' / 'longRest'

  @override
  void initState() {
    super.initState();
    _workMinutes = widget.config.workMinutes;
    _shortBreakMinutes = widget.config.shortBreakMinutes;
    _longBreakMinutes = widget.config.longBreakMinutes;
    _isPomodoroMode = widget.config.isPomodoroMode;
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('🍅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Pomodoro Mode',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.gold(context).withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'Pro',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gold(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Work in focused bursts with automatic breaks\n(Allow Notifications!)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 20),
          if (!isPremium) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold(context).withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  Text(
                    'Pomodoro Mode is a Pro feature',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upgrade to unlock automatic work/break cycles, customizable intervals, and more.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        useRootNavigator: true,
                        builder: (_) => const FeaturePaywallScreen(source: 'pomodoro',),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold(context),
                      foregroundColor: AppColors.goldText(context),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: Text(
                      'Upgrade to Pro',
                      style: AppTextStyles.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildToggle(context),
            const SizedBox(height: 8),

            if (_isPomodoroMode) ...[
              ExpandablePickerRow(
                icon: Icons.laptop_mac_rounded,
                label: 'Work',
                value: _workMinutes,
                min: 5,
                max: 480,
                step: 5,
                isExpanded: _expandedRow == 'work', // 👈 new
                onToggle: () => setState(() {
                  _expandedRow = _expandedRow == 'work' ? null : 'work'; // 👈 tap again to collapse
                }),
                onChanged: (v) => setState(() => _workMinutes = v),
              ),
              Divider(color: AppColors.border(context), height: 1),
              ExpandablePickerRow(
                icon: Icons.local_cafe_rounded,
                label: 'Rest',
                value: _shortBreakMinutes,
                min: 5,
                max: 480,
                step: 5,
                isExpanded: _expandedRow == 'rest', // 👈 new
                onToggle: () => setState(() {
                  _expandedRow = _expandedRow == 'rest' ? null : 'rest';
                }),
                onChanged: (v) => setState(() => _shortBreakMinutes = v),
              ),
              Divider(color: AppColors.border(context), height: 1),
              ExpandablePickerRow(
                icon: Icons.self_improvement_rounded,
                label: 'Long Rest (4 rounds)',
                value: _longBreakMinutes,
                min: 5,
                max: 480,
                step: 5,
                isExpanded: _expandedRow == 'longRest', // 👈 new
                onToggle: () => setState(() {
                  _expandedRow = _expandedRow == 'longRest' ? null : 'longRest';
                }),
                onChanged: (v) => setState(() => _longBreakMinutes = v),
              ),
              const SizedBox(height: 12),
            ],
            // save button
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await NotificationService.instance.requestPermission();
                if (_isPomodoroMode) {
                  await NotificationService.instance.requestExactAlarmPermission();
                }
                widget.onSave(PomodoroConfig(
                  workMinutes: _workMinutes,
                  shortBreakMinutes: _shortBreakMinutes,
                  longBreakMinutes: _longBreakMinutes,
                  isPomodoroMode: _isPomodoroMode,
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold(context),
                foregroundColor: AppColors.goldText(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.labelLarge,
              ),
              child: const Text('Save'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isPomodoroMode = !_isPomodoroMode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isPomodoroMode
                ? const Color(0xFFE74C3C).withValues(alpha: 0.4)
                : AppColors.border(context),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Text('🍅', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enable',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: _isPomodoroMode
                    ? const Color(0xFFE74C3C)
                    : AppColors.backgroundCard(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border(context),
                  width: 0.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _isPomodoroMode
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary(context),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expandable picker row ─────────────────────────────
class ExpandablePickerRow extends StatelessWidget { // 👈 was StatefulWidget
  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final bool isExpanded; // 👈 new — controlled by parent
  final VoidCallback onToggle; // 👈 new — tells parent "I was tapped"
  final ValueChanged<int> onChanged;

  const ExpandablePickerRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.isExpanded,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            onToggle(); // 👈 was setState(() => _expanded = !_expanded)
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary(context), size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const Spacer(),
                Text(
                  formatDuration(value),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0, // 👈 was _expanded
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary(context),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond, // 👈 was _expanded
          firstChild: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: HorizontalRulerPicker(
              value: value,
              min: min,
              max: max,
              step: step,
              onChanged: onChanged,
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          formatDuration(widget.value),
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: _FlankingLabels(value: widget.value),
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
                        final isMajor = v % 30 == 0;
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

  const _FlankingLabels({required this.value});

  @override
  Widget build(BuildContext context) {
    final leftLabel = (value - 30).clamp(5, 480);
    final rightLabel = (value + 30).clamp(5, 480);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          formatDuration(leftLabel),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary(context).withValues(alpha: 0.6),
          ),
        ),
        Text(
          formatDuration(rightLabel),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary(context).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}