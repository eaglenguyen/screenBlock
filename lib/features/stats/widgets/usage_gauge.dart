import 'dart:math';
import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.state.gaugeValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(UsageGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.gaugeValue != widget.state.gaugeValue) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.state.gaugeValue,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _buildGauge(),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildGauge() {
    return SizedBox(
      width: 200,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(200, 120),
                painter: _GaugePainter(
                  value: _animation.value,
                  isOverGoal: widget.state.isOverGoal,
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            child: Column(
              children: [
                Text(
                  widget.state.formattedTotal,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.state.percentLeft}% left',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: widget.state.isOverGoal
                            ? AppColors.error
                            : AppColors.gold,
                      ),
                    ),
                    Text(
                      '  |  ',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      widget.state.formattedGoal,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppColors.gold, 'Used'),
        const SizedBox(width: 16),
        _legendItem(AppColors.backgroundSubtle, 'Remaining'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.isOverGoal,
  });

  final double value;
  final bool isOverGoal;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 16;
    const startAngle = pi;
    const sweepAngle = pi;

    final trackPaint = Paint()
      ..color = const Color(0xFF252542)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = isOverGoal
          ? const Color(0xFFE74C3C)
          : const Color(0xFFEDB82A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    // background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // filled arc
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * value,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.isOverGoal != isOverGoal;
}