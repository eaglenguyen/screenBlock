import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _outerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _innerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _outerAnim = Tween<double>(begin: 0, end: widget.state.gaugeValue)
        .animate(CurvedAnimation(
      parent: _outerCtrl,
      curve: Curves.easeOutCubic,
    ));
    _innerAnim = Tween<double>(begin: 0, end: widget.state.blockedGaugeValue)
        .animate(CurvedAnimation(
      parent: _innerCtrl,
      curve: Curves.easeOutCubic,
    ));
    _outerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _innerCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(UsageGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.gaugeValue != widget.state.gaugeValue) {
      _outerAnim = Tween<double>(
        begin: _outerAnim.value,
        end: widget.state.gaugeValue,
      ).animate(CurvedAnimation(parent: _outerCtrl, curve: Curves.easeOutCubic));
      _outerCtrl..reset()..forward();
    }
    if (oldWidget.state.blockedGaugeValue != widget.state.blockedGaugeValue) {
      _innerAnim = Tween<double>(
        begin: _innerAnim.value,
        end: widget.state.blockedGaugeValue,
      ).animate(CurvedAnimation(parent: _innerCtrl, curve: Curves.easeOutCubic));
      _innerCtrl..reset()..forward();
    }
  }

  @override
  void dispose() {
    _outerCtrl.dispose();
    _innerCtrl.dispose();
    super.dispose();
  }

  Color get _outerColor {
    if (widget.state.gaugeValue >= 0.8) return const Color(0xFFE74C3C);
    if (widget.state.gaugeValue >= 0.5) return const Color(0xFFFF8C00);
    return const Color(0xFF4CAF50);
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // ── Rings (left side) ──────────────────────
          SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: Listenable.merge([_outerAnim, _innerAnim]),
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(160, 160),
                  painter: _DualRingPainter(
                    outerValue: _outerAnim.value,
                    innerValue: _innerAnim.value,
                    isOverGoal: widget.state.isOverGoal,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 20),

          // ── Stats (right side) ────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // screen time stat
                _statRow(
                  label: 'Screen Time',
                  value: widget.state.formattedTotal,
                  goal: widget.state.formattedGoal,
                  color: _outerColor,
                  suffix: widget.state.isOverGoal
                      ? '+${_formatOverage()} over'
                      : '${widget.state.percentLeft}% left',
                  isOverGoal: widget.state.isOverGoal,
                ),

                const SizedBox(height: 6),
                Container(
                  height: 0.5,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 6),

                // blocked time stat
                _statRow(
                  label: 'Blocked',
                  value: widget.state.formattedBlocked,
                  goal: widget.state.formattedBlockGoal,
                  color: const Color(0xFF4ECDC4),
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
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: ' / ${goal.replaceAll(' goal', '')}',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          suffix,
          style: GoogleFonts.poppins(
            color: isOverGoal
                ? const Color(0xFFE74C3C)
                : color.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DualRingPainter extends CustomPainter {
  const _DualRingPainter({
    required this.outerValue,
    required this.innerValue,
    required this.isOverGoal,
  });

  final double outerValue;
  final double innerValue;
  final bool isOverGoal;

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
      if (outerValue >= 0.8) return const Color(0xFFE74C3C);
      if (outerValue >= 0.5) return const Color(0xFFFF8C00);
      return const Color(0xFF4CAF50);
    }

    final remainingValue = (1.0 - outerValue).clamp(0.0, 1.0);

    // ── Outer track ───────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle, fullSweep, false,
      Paint()
        ..color = const Color(0xFF252542)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // ── Outer fill (remaining) ────────────────────
    final outerFillPaint = Paint()
      ..color = outerColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (remainingValue > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        fullSweep * remainingValue,
        false,
        outerFillPaint,
      );
    } else {
      // red dot at top when over goal
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle, 0.001, false,
        Paint()
          ..color = const Color(0xFFE74C3C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Inner track ───────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle, fullSweep, false,
      Paint()
        ..color = const Color(0xFF252542)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // ── Inner fill (blocked) ──────────────────────
    if (innerValue > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        fullSweep * innerValue.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = const Color(0xFF4ECDC4)
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
          old.isOverGoal != isOverGoal;
}