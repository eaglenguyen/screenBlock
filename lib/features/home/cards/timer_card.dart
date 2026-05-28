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

    if (widget.shouldAnimate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAnimationStarted?.call(); // reset flag
        _startSlotSpin(to: widget.blockedTime);
      });
    }
  }

  @override
  void didUpdateWidget(TimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSpinning) {
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

    // fast spin phase — 800ms
    const spinDuration = Duration(milliseconds: 800);
    const tickInterval = Duration(milliseconds: 100); // 👈 slower = smoother

    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < spinDuration) {
      await Future.delayed(tickInterval);
      if (!mounted) return;

      final n = stopwatch.elapsed.inMilliseconds;
      setState(() {
        _spinValues = [
          ((n ~/ 7) % 60).toString().padLeft(2, '0'),
          ((n ~/ 5) % 60).toString().padLeft(2, '0'),
          ((n ~/ 3) % 60).toString().padLeft(2, '0'),
        ];
      });
      HapticFeedback.lightImpact();
    }

    // settle — each digit locks in with 200ms gap
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _spinValues = [finalHours, ((stopwatch.elapsed.inMilliseconds ~/ 5) % 60).toString().padLeft(2, '0'), ((stopwatch.elapsed.inMilliseconds ~/ 3) % 60).toString().padLeft(2, '0')]);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _spinValues = [finalHours, finalMinutes, ((stopwatch.elapsed.inMilliseconds ~/ 3) % 60).toString().padLeft(2, '0')]);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _spinValues = [finalHours, finalMinutes, finalSeconds]);
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() {
      _displayTime = to;
      _isSpinning = false;
    });
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
      duration: const Duration(milliseconds: 150),
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
          SizedBox(
            height: 58,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              child: Text(
                value,
                key: ValueKey(value),
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: 48,
                  color: _isSpinning
                      ? AppColors.gold
                      : AppColors.textSecondary,
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