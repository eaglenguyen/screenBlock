import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../paywall/feature_paywall_screen.dart';
import '../../../providers/premium_provider.dart';
import '../../../services/notification_service.dart';

const _proOrange = Color(0xFFF2A340);

// ── Pomodoro config ──────────────────────────────────────────────────────────
class PomodoroConfig {
  final int workMinutes;
  final int shortBreakMinutes;
  final bool isPomodoroMode;
  final bool autoStartBreak;
  const PomodoroConfig({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.isPomodoroMode = false,
    this.autoStartBreak = true,
  });
  PomodoroConfig copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    bool? isPomodoroMode,
    bool? autoStartBreak,
  }) {
    return PomodoroConfig(
      workMinutes: workMinutes ?? this.workMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      isPomodoroMode: isPomodoroMode ?? this.isPomodoroMode,
      autoStartBreak: autoStartBreak ?? this.autoStartBreak,
    );
  }
}

String formatDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

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
  late bool _isPomodoroMode;
  late bool _autoStartBreak;

  String? _expandedRow;

  @override
  void initState() {
    super.initState();
    _workMinutes = widget.config.workMinutes;
    _shortBreakMinutes = widget.config.shortBreakMinutes;
    _isPomodoroMode = widget.config.isPomodoroMode;
    _autoStartBreak = widget.config.autoStartBreak;
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
              const Spacer(),// "Pro" badge in the header row
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient( // 👈 was color: _proOrange
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE8623D), Color(0xFFF2A340)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'Pro',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else if (_isPomodoroMode)
                GestureDetector(
                  onTap: () => setState(() => _autoStartBreak = !_autoStartBreak),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSubtle(context),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.border(context), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Auto-start',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary(context),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _autoStartBreak ? _proOrange : AppColors.backgroundCard(context), // 👈 was AppColors.accent(context)
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: AppColors.border(context), width: 0.5),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _autoStartBreak ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.all(1.5),
                              width: 13,
                              height: 13,
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
                  color: _proOrange.withValues(alpha: 0.3), // 👈 was AppColors.accent(context)
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
                  // "Upgrade to Pro" button
                  Container( // 👈 wraps the button so we can apply a gradient (ElevatedButton itself doesn't support gradient fills directly)
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE8623D), Color(0xFFF2A340)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ElevatedButton(
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
                        backgroundColor: Colors.transparent, // 👈 was _proOrange — transparent so the gradient behind shows through
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent, // 👈 new — avoids a double-shadow look from the ElevatedButton's own elevation
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        minimumSize: const Size(double.infinity, 0),
                        elevation: 0,
                      ),
                      child: Text(
                        'Upgrade to Pro',
                        style: AppTextStyles.labelLarge,
                      ),
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
                isExpanded: _expandedRow == 'work',
                onToggle: () => setState(() {
                  _expandedRow = _expandedRow == 'work' ? null : 'work';
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
                isExpanded: _expandedRow == 'rest',
                onToggle: () => setState(() {
                  _expandedRow = _expandedRow == 'rest' ? null : 'rest';
                }),
                onChanged: (v) => setState(() => _shortBreakMinutes = v),
              ),

              const SizedBox(height: 12),
            ],
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
                  isPomodoroMode: _isPomodoroMode,
                  autoStartBreak: _autoStartBreak,
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _proOrange, // 👈 was AppColors.accent(context)
                foregroundColor: Colors.white, // 👈 was AppColors.accentText(context)
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.labelLarge,
              ),
              child: const Text('Save Settings'),
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
class ExpandablePickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final bool isExpanded;
  final VoidCallback onToggle;
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
            onToggle();
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
                  turns: isExpanded ? 0.5 : 0,
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
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
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