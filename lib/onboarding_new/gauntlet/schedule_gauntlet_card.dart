import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausenow/onboarding_new/gauntlet/schedule_gauntlet_state.dart';

class ScheduleGauntletCard extends StatefulWidget {
  final ScheduleGauntletState state;
  final ScheduleStone? justFilled; // 👈 which stone to animate on this build, null = no animation

  const ScheduleGauntletCard({
    super.key,
    required this.state,
    this.justFilled,
  });

  @override
  State<ScheduleGauntletCard> createState() => _ScheduleGauntletCardState();
}

class _ScheduleGauntletCardState extends State<ScheduleGauntletCard> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;

  static const _stoneColors = {
    ScheduleStone.name: Color(0xFFEE8FA8),
    ScheduleStone.time: Color(0xFF7FB4E8),
    ScheduleStone.apps: Color(0xFF7FC9BB),
    ScheduleStone.days: Color(0xFFB398E8),
  };

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    if (widget.justFilled != null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _flashController.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        final flash = (1 - _flashController.value).clamp(0.0, 1.0);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.justFilled != null
                  ? Color.lerp(const Color(0xFFF0E6D8), _stoneColors[widget.justFilled]!, flash)!
                  : const Color(0xFFF0E6D8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0DA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.safety_check_outlined, color: Color(0xFFB07A1E), size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.state.hasName ? widget.state.name! : 'Block Schedule',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF4A3728)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.state.timeLabel} · ${widget.state.appsLabel} · ${widget.state.daysLabel}',
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFB08A5A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}