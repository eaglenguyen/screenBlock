import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget/continue_button.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;

  const OnboardingWelcomeScreen({super.key, required this.onGetStarted});

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  String _displayText = '';

  final _orbitIcons = [
    _OrbitIcon(asset: 'assets/icons/instagram.png', angleOffset: pi / 4, showBackground: false), // 👈 new
    _OrbitIcon(icon: Icons.explore_rounded, color: const Color(0xFF3478F6), bg: const Color(0xFFDCEBFF), angleOffset: pi / 2),
    _OrbitIcon(asset: 'assets/icons/youtube.png', angleOffset: 3 * pi / 4),
    _OrbitIcon(icon: Icons.fastfood, color: const Color(0xFF2D7A54), bg: const Color(0xFFDFF3EA), angleOffset: pi),
    _OrbitIcon(asset: 'assets/icons/tiktok.png', angleOffset: 0, showBackground: false), // 👈 new
    _OrbitIcon(icon: Icons.menu_book_rounded, color: const Color(0xFFB07A1E), bg: const Color(0xFFFFF0DA), angleOffset: 5 * pi / 4),
    _OrbitIcon(icon: Icons.compass_calibration_rounded, color: const Color(0xFF3478F6), bg: const Color(0xFFDCEBFF), angleOffset: 3 * pi / 2),
    _OrbitIcon(asset: 'assets/icons/twitter.png', angleOffset: 7 * pi / 4),
  ];

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _startTypewriter();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  Future<void> _startTypewriter() async {
    const phrases = [
      'Block your unproductive apps',
      'Spin the wheel instead of scrolling',
      'Break the doomscroll cycle',
      'Every spin beats another scroll',
    ];

    await Future.delayed(const Duration(milliseconds: 500));

    int phraseIndex = 0;
    while (mounted) {
      final phrase = phrases[phraseIndex];

      for (int i = 0; i < phrase.length; i++) {
        if (!mounted) return;
        HapticFeedback.lightImpact();
        setState(() {
          _displayText = phrase.substring(0, i + 1);
        });
        await Future.delayed(const Duration(milliseconds: 40));
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      setState(() => _displayText = '');
      await Future.delayed(const Duration(milliseconds: 400));

      phraseIndex = (phraseIndex + 1) % phrases.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED), // 👈 app's light background
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            SizedBox(
              height: 300,
              width: 300,
              child: AnimatedBuilder(
                animation: _orbitController,
                builder: (context, child) {
                  final t = _orbitController.value * 2 * pi;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF4A3728).withValues(alpha: 0.08), width: 1),
                        ),
                      ),
                      Image.asset(
                        'assets/images/logowithwheeltrans.png', // 👈 adjust to your actual saved filename/path
                        height: 80, // 👈 tune to match the visual weight of the old text
                      ),
                      for (final orbit in _orbitIcons)
                        _buildOrbitingIcon(orbit, t, radius: 130),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 28,
              child: Text(
                _displayText,
                style: GoogleFonts.poppins(
                  color: Colors.black87, // 👈 textPrimary at reduced opacity
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: OnboardingContinueButton(
                label: 'Get Started',
                onTap: widget.onGetStarted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitingIcon(_OrbitIcon orbit, double t, {required double radius}) {
    final angle = orbit.angleOffset + t;
    final x = radius * cos(angle);
    final y = radius * sin(angle);

    final iconContent = orbit.asset != null
        ? (orbit.asset!.endsWith('.svg') // 👈 new — branch by file type
        ? SvgPicture.asset(
      orbit.asset!,
      width: 22,
      height: 22,
      colorFilter: orbit.color != null ? ColorFilter.mode(orbit.color!, BlendMode.srcIn) : null,
    )
        : Image.asset( // 👈 new — PNG path
      orbit.asset!,
      width: orbit.showBackground ? 22 : 36, // 👈 bigger when there's no circle padding it out
      height: orbit.showBackground ? 22 : 36,
    ))
        : Icon(orbit.icon, color: orbit.color, size: 22);

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: -t,
        child: orbit.showBackground // 👈 new — skip the circle Container entirely when false
            ? Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: orbit.bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Center(child: iconContent),
        )
            : iconContent, // 👈 just the raw PNG/icon, no circle, no shadow, no background at all
      ),
    );
  }
}

class _OrbitIcon {
  final String? asset;
  final IconData? icon;
  final Color? color;
  final Color? bg; // 👈 was required Color bg — now optional
  final double angleOffset;
  final bool showBackground; // 👈 new — set false for transparent PNGs you don't want circled

  const _OrbitIcon({
    this.asset,
    this.icon,
    this.color,
    this.bg,
    required this.angleOffset,
    this.showBackground = true, // 👈 new — defaults to true, so existing icons keep their circle
  });
}