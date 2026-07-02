import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/premium_provider.dart';
import '../../paywall/feature_paywall_screen.dart';

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
          // handle
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

          // header
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
            // locked state
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
                        builder: (_) => const FeaturePaywallScreen(),
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
            // toggle
            _buildToggle(context),
            const SizedBox(height: 16),

            if (_isPomodoroMode) ...[
              _buildDurationRow(
                context,
                emoji: '💼',
                label: 'Work',
                minutes: _workMinutes,
                min: 2,
                max: 60,
                defaultValue: 25, // 👈
                onChanged: (v) => setState(() => _workMinutes = v),
              ),
              const SizedBox(height: 10),
              _buildDurationRow(
                context,
                emoji: '☕',
                label: 'Short Break',
                minutes: _shortBreakMinutes,
                min: 2,
                max: 15,
                defaultValue: 5, // 👈
                onChanged: (v) => setState(() => _shortBreakMinutes = v),
              ),
              const SizedBox(height: 10),
              _buildDurationRow(
                context,
                emoji: '🧘',
                label: 'Long Break (4 rounds)',
                minutes: _longBreakMinutes,
                min: 15,
                max: 60,
                defaultValue: 30,
                onChanged: (v) => setState(() => _longBreakMinutes = v),
              ),
              const SizedBox(height: 20),
            ],

            // save button
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
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

  Widget _buildDurationRow(
      BuildContext context, {
        required String emoji,
        required String label,
        required int minutes,
        required int min,
        required int max,
        required int defaultValue,  // 👈 add this for reset
        required ValueChanged<int> onChanged,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          Row(
            children: [
              _HoldStepButton(
                icon: Icons.remove,
                enabled: minutes > min,
                onStep: () {
                  HapticFeedback.lightImpact();
                  onChanged((minutes - 1).clamp(min, max));
                },
                onFastStep: () {
                  HapticFeedback.selectionClick();
                  onChanged((minutes - 5).clamp(min, max));
                },
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${minutes}m',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.gold(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _HoldStepButton(
                icon: Icons.add,
                enabled: minutes < max,
                onStep: () {
                  HapticFeedback.lightImpact();
                  onChanged((minutes + 1).clamp(min, max));
                },
                onFastStep: () {
                  HapticFeedback.selectionClick();
                  onChanged((minutes + 5).clamp(min, max));
                },
              ),
              // 👇 reset button
              if (minutes != defaultValue) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onChanged(defaultValue);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border(context),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }




  Widget _stepButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? AppColors.textPrimary(context)
              : AppColors.textSecondary(context),
        ),
      ),
    );
  }
}

class _HoldStepButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onStep;
  final VoidCallback onFastStep;

  const _HoldStepButton({
    required this.icon,
    required this.enabled,
    required this.onStep,
    required this.onFastStep,
  });

  @override
  State<_HoldStepButton> createState() => _HoldStepButtonState();
}

class _HoldStepButtonState extends State<_HoldStepButton> {
  Timer? _holdTimer;
  int _holdCount = 0;

  void _startHold() {
    if (!widget.enabled) return;
    widget.onStep(); // immediate first step
    _holdCount = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!widget.enabled) {
        _stopHold();
        return;
      }
      _holdCount++;
      // after 5 ticks (~0.75s) switch to fast +5 increments
      if (_holdCount > 5) {
        widget.onFastStep();
      } else {
        widget.onStep();
      }
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdCount = 0;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _stopHold(),
      onTapCancel: _stopHold,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Icon(
          widget.icon,
          size: 16,
          color: widget.enabled
              ? AppColors.textPrimary(context)
              : AppColors.textSecondary(context),
        ),
      ),
    );
  }
}

