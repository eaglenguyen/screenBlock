import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Time Blocked Today',
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 25),
          ),
          const SizedBox(height: 8),
          _buildRecordPill(),
          const SizedBox(height: 16),
          _buildTimerDisplay(hours, minutes, seconds),
          const SizedBox(height: 16),
          _buildSelectorRow(),
          const SizedBox(height: 14),
          _buildBlockNowButton(),
        ],
      ),
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
        _displayTime == '00:00:00'
            ? 'No sessions today yet'
            : "Today's blocked time",
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
          _timerColon(),
          Flexible(child: _timerBlock(minutes, 'Minutes')),
          _timerColon(),
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
      padding: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
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
    final isAllApps =
        widget.blockingType == AppConstants.blockingTypeAllApps;

    return Row(
      children: [
        Expanded(
          child: _selectorPill(
            icon: '🛡️',
            label: isAllApps ? 'All Apps' : 'Specific Apps',
            onTap: widget.onBlockModeTapped,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _selectorPill(
            icon: '⏱',
            label: widget.selectedMinutes < 60
                ? '${widget.selectedMinutes}m'
                : '${widget.selectedMinutes ~/ 60}h',
            iconColor: AppColors.gold(context),
            onTap: widget.onTimerTapped,
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

  Widget _buildBlockNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onBlockNow,
        icon: Icon(
          Icons.play_arrow_rounded,
          color: AppColors.goldText(context),
          size: 30,
        ),
        label: const Text('Block Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold(context),
          foregroundColor: AppColors.goldText(context),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 25),
        ),
      ),
    );
  }
}