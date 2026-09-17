// lib/onboarding_new/widget/slot_machine_years.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SlotMachineYears extends StatefulWidget {
  final int value;
  final Color color;
  final Duration startDelay; // 👈 new — lets the caller sync the spin's start with its own reveal timing

  const SlotMachineYears({
    super.key,
    required this.value,
    this.color = const Color(0xFFB398E8),
    this.startDelay = Duration.zero, // 👈 new
  });

  @override
  State<SlotMachineYears> createState() => _SlotMachineYearsState();
}

class _SlotMachineYearsState extends State<SlotMachineYears> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<int> _digits;
  late List<Animation<double>> _digitAnimations;

  static const double _digitHeight = 64;
  static const int _loops = 3;



  @override
  void initState() {
    super.initState();
    _digits = widget.value.toString().split('').map(int.parse).toList();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));

    _digitAnimations = List.generate(_digits.length, (i) {
      final targetDigit = _digits[i];
      final finalPosition = (_loops * 10 + targetDigit).toDouble();
      final start = i * 0.12;
      final end = (start + 0.75).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: finalPosition).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOutCubic)),
      );
    });

    for (int i = 0; i < _digitAnimations.length; i++) {
      _digitAnimations[i].addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          HapticFeedback.mediumImpact();
        }
      });
    }

    Future.delayed(widget.startDelay, () { // 👈 new — spin doesn't start until the row is actually visible
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...List.generate(_digits.length, (i) {
          return Transform.translate(
            offset: const Offset(0, -6),
            child: _SlotReel(animation: _digitAnimations[i], digitHeight: _digitHeight, color: widget.color),
          );
        }),
        const SizedBox(width: 12), // 👈 was 10 — tighter gap before "years"
        SizedBox(
          height: _digitHeight,
          child: Center(
            child: Text(
              _digits.length == 1 && widget.value == 1 ? 'year' : 'years',
              style: GoogleFonts.poppins(
                color: widget.color,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlotReel extends StatelessWidget {
  final Animation<double> animation;
  final double digitHeight;
  final Color color;
  const _SlotReel({required this.animation, required this.digitHeight, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: 34,
        height: digitHeight,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            const totalStripDigits = 60;
            return ClipRect(
              child: OverflowBox(
                maxHeight: digitHeight * totalStripDigits,
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, -animation.value * digitHeight),
                  child: Column(
                    children: List.generate(totalStripDigits, (i) {
                      return SizedBox(
                        height: digitHeight,
                        child: Center(
                          child: Text(
                            (i % 10).toString(),
                            style: GoogleFonts.poppins(
                              color: color,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [FontFeature.tabularFigures()], // 👈 new — forces equal-width digits
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}