import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pausenow/core/theme/lipped_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../stats_state.dart';

class UsageGauge extends StatefulWidget {
  const UsageGauge({
    super.key,
    required this.state,
  });
  final StatsState state;

  @override
  State<UsageGauge> createState() => _UsageGaugeState();
}

class _UsageGaugeState extends State<UsageGauge>
    with TickerProviderStateMixin {
  late AnimationController _outerCtrl;
  late AnimationController _innerCtrl;
  late Animation<double> _outerAnim;
  late Animation<double> _innerAnim;

  @override
  void initState() {
    super.initState();
    _outerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _innerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _outerAnim = Tween<double>(begin: 0, end: widget.state.gaugeValue)
        .animate(CurvedAnimation(parent: _outerCtrl, curve: Curves.easeOutCubic));
    _innerAnim = Tween<double>(begin: 0, end: widget.state.blockedGaugeValue)
        .animate(CurvedAnimation(parent: _innerCtrl, curve: Curves.easeOutCubic));
    _outerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _innerCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(UsageGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.gaugeValue != widget.state.gaugeValue) {
      _outerAnim = Tween<double>(begin: _outerAnim.value, end: widget.state.gaugeValue)
          .animate(CurvedAnimation(parent: _outerCtrl, curve: Curves.easeOutCubic));
      _outerCtrl..reset()..forward();
    }
    if (oldWidget.state.blockedGaugeValue != widget.state.blockedGaugeValue) {
      _innerAnim = Tween<double>(begin: _innerAnim.value, end: widget.state.blockedGaugeValue)
          .animate(CurvedAnimation(parent: _innerCtrl, curve: Curves.easeOutCubic));
      _innerCtrl..reset()..forward();
    }
  }

  @override
  void dispose() {
    _outerCtrl.dispose();
    _innerCtrl.dispose();
    super.dispose();
  }

  Color _outerColor(BuildContext context) {
    if (widget.state.gaugeValue >= 0.8) return AppColors.error(context);
    if (widget.state.gaugeValue >= 0.5) return AppColors.warning(context);
    return AppColors.success(context);
  }

  String _formatOverage() {
    final over = widget.state.totalUsage - widget.state.dailyGoal;
    final hours = over.inHours;
    final minutes = over.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return LippedCard(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: Listenable.merge([_outerAnim, _innerAnim]),
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(160, 160),
                  painter: _DualRingPainter(
                    context: context, // 👈 new
                    outerValue: _outerAnim.value,
                    innerValue: _innerAnim.value,
                    isOverGoal: widget.state.isOverGoal,
                    showOuterRing: !Platform.isIOS,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!Platform.isIOS) ...[
                  _statRow(
                    context: context,
                    label: 'Screen Time',
                    value: widget.state.totalUsage > Duration.zero ? widget.state.formattedTotal : '--',
                    goal: widget.state.formattedGoal,
                    color: _outerColor(context),
                    suffix: widget.state.totalUsage > Duration.zero
                        ? widget.state.isOverGoal
                        ? '+${_formatOverage()} over'
                        : '${widget.state.percentLeft}% left'
                        : '0% of goal',
                    isOverGoal: widget.state.isOverGoal,
                  ),
                  const SizedBox(height: 8),
                  Container(height: 0.5, color: AppColors.border(context)),
                  const SizedBox(height: 8),
                ],
                _statRow(
                  context: context,
                  label: 'Block Time',
                  value: widget.state.formattedBlocked,
                  goal: widget.state.formattedBlockGoal,
                  color: AppColors.accent(context),
                  suffix: widget.state.blockedGaugeValue >= 1.0
                      ? 'Goal hit! 🎉'
                      : '${(widget.state.blockedGaugeValue * 100).round()}% of goal',
                  isOverGoal: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow({
    required BuildContext context,
    required String label,
    required String value,
    required String goal,
    required Color color,
    required String suffix,
    required bool isOverGoal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith( // 👈 was bodySmall (11px) — bumped to bodyMedium (13px)
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTextStyles.displaySmall.copyWith(color: color, letterSpacing: -1, fontWeight: FontWeight.w800),              ),
              TextSpan(
                text: ' / ${goal.replaceAll(' goal', '')}',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary(context)), // 👈 was bodyMedium (13px) — bumped to bodyLarge (15px)
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          suffix,
          style: AppTextStyles.bodyMedium.copyWith( // 👈 was bodySmall (11px) — bumped to bodyMedium (13px)
            color: isOverGoal ? AppColors.error(context) : color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DualRingPainter extends CustomPainter {
  const _DualRingPainter({
    required this.context, // 👈 new
    required this.outerValue,
    required this.innerValue,
    required this.isOverGoal,
    this.showOuterRing = true,
  });
  final BuildContext context; // 👈 new
  final double outerValue;
  final double innerValue;
  final bool isOverGoal;
  final bool showOuterRing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const startAngle = -pi / 2;
    const fullSweep = 2 * pi;
    const strokeWidth = 16.0;
    const ringGap = 8.0;
    final outerRadius = size.width / 2 - strokeWidth / 2 - 2;
    final innerRadius = outerRadius - strokeWidth - ringGap;

    Color outerColor() {
      if (outerValue >= 0.8) return AppColors.error(context);
      if (outerValue >= 0.5) return AppColors.warning(context);
      return AppColors.success(context);
    }

    final remainingValue = (1.0 - outerValue).clamp(0.0, 1.0);
    final trackColor = AppColors.backgroundSubtle(context);

    if (showOuterRing) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle, fullSweep, false,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      final outerFillPaint = Paint()
        ..color = outerColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (remainingValue > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle, fullSweep * remainingValue, false, outerFillPaint,
        );
      } else {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle, 0.001, false,
          Paint()
            ..color = AppColors.error(context)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    final innerDrawRadius = showOuterRing ? innerRadius : outerRadius;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerDrawRadius),
      startAngle, fullSweep, false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (innerValue > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerDrawRadius),
        startAngle, fullSweep * innerValue.clamp(0.0, 1.0), false,
        Paint()
          ..color = AppColors.accent(context)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_DualRingPainter old) =>
      old.outerValue != outerValue ||
          old.innerValue != innerValue ||
          old.isOverGoal != isOverGoal ||
          old.showOuterRing != showOuterRing;
}