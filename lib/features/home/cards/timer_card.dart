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

  late AnimationController _spinController;
  bool _isSpinning = false;
  String _displayTime = '00:00:00';
  List<String> _spinValues = ['00', '00', '00'];

  @override
  void initState() {
    super.initState();
    _displayTime = widget.blockedTime;
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didUpdateWidget(TimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldAnimate && !oldWidget.shouldAnimate && !_isSpinning) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // call back to parent to reset flag
        // pass a resetFlag callback from HomeScreen
      });
      _startSlotSpin(to: widget.blockedTime);
    } else if (!widget.shouldAnimate) {
      setState(() => _displayTime = widget.blockedTime);
    }
  }

  Future<void> _startSlotSpin({required String to}) async {
    setState(() => _isSpinning = true);
    widget.onAnimationStarted?.call();

    final parts = to.split(':');
    final finalHours = parts[0];
    final finalMinutes = parts[1];
    final finalSeconds = parts[2];

    // spin fast for 1.5s then settle
    final spinDuration = const Duration(milliseconds: 1500);
    final settleDuration = const Duration(milliseconds: 500);
    final tickInterval = const Duration(milliseconds: 60);

    final stopwatch = Stopwatch()..start();

    // fast spin phase
    while (stopwatch.elapsed < spinDuration) {
      await Future.delayed(tickInterval);
      if (!mounted) return;
      setState(() {
        _spinValues = [
          _randomTwoDigit(),
          _randomTwoDigit(),
          _randomTwoDigit(),
        ];
      });
      HapticFeedback.lightImpact();
    }

    // settle phase — each digit locks in one by one
    await Future.delayed(settleDuration ~/ 3);
    if (!mounted) return;
    setState(() => _spinValues = [finalHours, _randomTwoDigit(), _randomTwoDigit()]);
    HapticFeedback.mediumImpact();

    await Future.delayed(settleDuration ~/ 3);
    if (!mounted) return;
    setState(() => _spinValues = [finalHours, finalMinutes, _randomTwoDigit()]);
    HapticFeedback.mediumImpact();

    await Future.delayed(settleDuration ~/ 3);
    if (!mounted) return;
    setState(() => _spinValues = [finalHours, finalMinutes, finalSeconds]);
    HapticFeedback.heavyImpact();

    // final settle
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() {
      _displayTime = to;
      _isSpinning = false;
    });

    // reset flag in viewmodel
    // so animation doesn't retrigger on rebuild
  }

  String _randomTwoDigit() {
    final n = (DateTime.now().millisecondsSinceEpoch % 100);
    return n.toString().padLeft(2, '0');
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parts = _isSpinning
        ? _spinValues
        : _displayTime.split(':');

    final hours = parts[0];
    final minutes = parts[1];
    final seconds = parts[2];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSpinning
              ? AppColors.gold.withValues(alpha: 0.5)
              : AppColors.border,
          width: _isSpinning ? 1 : 0.5,
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
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        _isSpinning
            ? '🎰 Calculating...'
            : _displayTime == '00:00:00'
            ? 'No sessions today yet'
            : "Today's blocked time",
        style: AppTextStyles.bodySmall.copyWith(fontSize: 15),
      ),
    );
  }

  Widget _buildTimerDisplay(String hours, String minutes, String seconds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: _timerBlock(hours, 'Hours')),
        _timerColon(),
        Flexible(child: _timerBlock(minutes, 'Minutes')),
        _timerColon(),
        Flexible(child: _timerBlock(seconds, 'Seconds')),
      ],
    );
  }

  Widget _timerBlock(String value, String label) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: _isSpinning
            ? AppColors.gold.withValues(alpha: 0.08)
            : AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isSpinning
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 50),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Text(
              value,
              key: ValueKey('$value${DateTime.now().millisecondsSinceEpoch ~/ 50}'),
              style: AppTextStyles.displayMedium.copyWith(
                fontSize: 48,
                color: _isSpinning
                    ? AppColors.gold
                    : AppColors.textSecondary,
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
          color: _isSpinning ? AppColors.gold : AppColors.border,
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
            iconColor: AppColors.gold,
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
          color: AppColors.backgroundSubtle,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 14, color: iconColor)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: AppTextStyles.labelMedium),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
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
        icon: const Icon(
          Icons.play_arrow_rounded,
          color: AppColors.goldText,
          size: 30,
        ),
        label: const Text('Block Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.goldText,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 25),
        ),
      ),
    );
  }
}