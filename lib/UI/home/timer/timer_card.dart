import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausenow/core/theme/lipped_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';


class TimerCard extends StatefulWidget {
  final VoidCallback onBlockNow;
  final ValueChanged<String> onSelectorTapped;
  final VoidCallback onBlockModeTapped;
  final String blockingType;
  final VoidCallback onTimerTapped;
  final int selectedMinutes;
  final String blockedTime;
  final bool shouldAnimate;
  final VoidCallback? onAnimationStarted;
  final VoidCallback onTutorialTap;
  final bool isScheduleActive;
  final bool isAppLimitActiveToday;
  final VoidCallback onPomodoroTapped;
  final bool isPomodoroMode;
  final int? pomodoroRestMinutes; // 👈 new

  final GlobalKey? blockModeKey; // 👈 new
  final GlobalKey? timerModeKey; // 👈 new
  final GlobalKey? startButtonKey; // 👈 new

  const TimerCard({
    super.key,
    required this.onBlockNow,
    required this.onSelectorTapped,
    required this.onBlockModeTapped,
    required this.blockingType,
    required this.onTimerTapped,
    required this.selectedMinutes,
    required this.blockedTime,
    this.shouldAnimate = false,
    required this.onAnimationStarted,
    required this.onTutorialTap,
    this.isScheduleActive = false,
    this.isAppLimitActiveToday = false,
    required this.onPomodoroTapped,
    this.isPomodoroMode = false,
    this.pomodoroRestMinutes, // 👈 new
    this.blockModeKey,
    this.timerModeKey,
    this.startButtonKey,
  });

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard>
    with TickerProviderStateMixin {

  late AnimationController _punchCtrl;
  late Animation<double> _punchScale;
  String _displayTime = '00:00:00';

  @override
  void initState() {
    super.initState();
    _displayTime = widget.blockedTime;

    _punchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _punchScale = TweenSequence([
      // fast scale up — pops toward you
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      // elastic bounce back
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_punchCtrl);

    // trigger on first build if needed
    if (widget.shouldAnimate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerPunch(to: widget.blockedTime);
      });
    }
  }

  @override
  void didUpdateWidget(TimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // update display time whenever it changes
    if (oldWidget.blockedTime != widget.blockedTime) {
      setState(() => _displayTime = widget.blockedTime);
    }

    // trigger punch when shouldAnimate flips true
    if (widget.shouldAnimate && !oldWidget.shouldAnimate) {
      _triggerPunch(to: widget.blockedTime);
    }
  }

  void _triggerPunch({required String to}) {
    widget.onAnimationStarted?.call();
    setState(() => _displayTime = to);
    HapticFeedback.heavyImpact();
    _punchCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _punchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parts = _displayTime.split(':');
    final hours = parts[0];
    final minutes = parts[1];
    final seconds = parts[2];

    return Stack( // 👈 new wrapper
      children: [
        LippedCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildRecordPill(),
              const SizedBox(height: 16),
              _buildTimerDisplay(hours, minutes, seconds),
              const SizedBox(height: 16),
              _buildSelectorRow(),
              const SizedBox(height: 14),
              _buildBlockNowButton(),
            ],
          ),
        ),
        Positioned( // 👈 new — "?" pinned to top-right of the whole card
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: widget.onTutorialTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border(context), width: 0.5),
              ),
              child: Center(
                child: Text(
                  '?',
                  style: AppTextStyles.bodyLarge.copyWith( // 👈 was GoogleFonts.poppins directly
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildRecordPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        "Today's blocked time",
        style: AppTextStyles.bodySmall.copyWith(fontSize: 15),
      ),
    );
  }

  Widget _buildTimerDisplay(String hours, String minutes, String seconds) {
    return AnimatedBuilder(
      animation: _punchScale,
      builder: (_, child) => Transform.scale(
        scale: _punchScale.value,
        child: child,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: _timerBlock(hours, 'Hours')),
          const SizedBox(width: 8),   // 👈 add
          _timerColon(),
          const SizedBox(width: 8),   // 👈 add
          Flexible(child: _timerBlock(minutes, 'Minutes')),
          const SizedBox(width: 8),   // 👈 add
          _timerColon(),
          const SizedBox(width: 8),   // 👈 add
          Flexible(child: _timerBlock(seconds, 'Seconds')),
        ],
      ),
    );
  }

  Widget _timerBlock(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 58,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Text(
                value,
                key: ValueKey(value),
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: 48,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _timerColon() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        ':',
        style: AppTextStyles.displayMedium.copyWith(
          fontSize: 28,
          color: AppColors.border(context),
        ),
      ),
    );
  }

  Widget _buildSelectorRow() {
    final isAllApps = widget.blockingType == AppConstants.blockingTypeAllApps;
    return Row(
      children: [
        Expanded(
          child: KeyedSubtree( // 👈 new
            key: widget.blockModeKey,
            child: _selectorPill(
              icon: '',
              label: isAllApps ? 'All Apps' : 'Blocked Apps',
              onTap: widget.onBlockModeTapped,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KeyedSubtree( // 👈 new
            key: widget.timerModeKey,
            child: _selectorPill(
              icon: '⏱',
              label: _timerPillLabel(),
              iconColor: AppColors.accent(context),
              onTap: widget.onTimerTapped,
            ),
          ),
        ),
      ],
    );
  }

// 👇 new — combines work + rest when Pomodoro is active
  String _timerPillLabel() {
    final workLabel = _formatDuration(widget.selectedMinutes);
    if (widget.isPomodoroMode && widget.pomodoroRestMinutes != null) {
      final restLabel = _formatDuration(widget.pomodoroRestMinutes!);
      return '$workLabel / $restLabel';
    }
    return workLabel;
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }


  Widget _buildBlockNowButton() {
    final isDisabled = widget.isScheduleActive || widget.isAppLimitActiveToday;

    return Row(
      children: [
        Expanded(
          flex: 75, // 👈 new — 75% of the row width
          child: KeyedSubtree(
            key: widget.startButtonKey,
            child: ElevatedButton.icon(
              onPressed: isDisabled ? null : widget.onBlockNow,
              icon: Icon(
                isDisabled ? Icons.lock_clock_rounded : Icons.play_arrow_rounded,
                color: isDisabled ? AppColors.textSecondary(context) : AppColors.accentText(context),
                size: 30,
              ),
              label: Text(
                isDisabled ? '' : 'Start',
                style: const TextStyle(fontSize: 19),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled ? AppColors.backgroundSubtle(context) : AppColors.accent(context),
                foregroundColor: isDisabled ? AppColors.textSecondary(context) : AppColors.accentText(context),
                disabledBackgroundColor: AppColors.backgroundSubtle(context),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 25),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded( // 👈 new — was a fixed-size GestureDetector, now flexes to fill remaining width
          flex: 25, // 👈 new — 25% of the row width
          child: GestureDetector(
            onTap: widget.onPomodoroTapped,
            child: Container(
              height: 60, // 👈 new — matches the Start button's approximate height, since width is now flexible instead of fixed
              decoration: BoxDecoration(
                color: widget.isPomodoroMode
                    ? const Color(0xFFE74C3C).withValues(alpha: 0.15)
                    : AppColors.backgroundSubtle(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isPomodoroMode
                      ? const Color(0xFFE74C3C).withValues(alpha: 0.5)
                      : AppColors.border(context),
                  width: widget.isPomodoroMode ? 1.5 : 0.5,
                ),
              ),
              child: const Center(
                child: Text('🍅', style: TextStyle(fontSize: 28)),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _selectorPill({
    required String icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle(context),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 14, color: iconColor)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: AppTextStyles.labelMedium),
            ),
             Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }



}