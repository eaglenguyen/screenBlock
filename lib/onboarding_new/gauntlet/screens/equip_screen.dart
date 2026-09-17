// lib/onboarding_new/screens/gauntlet_equip_screen.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widget/continue_button.dart';
import '../gauntlet_stones.dart';
import '../schedule_gauntlet_card.dart';
import '../schedule_gauntlet_state.dart';

class OnboardingGauntletEquipScreen extends StatefulWidget {
  final ScheduleGauntletState state;
  final ScheduleStone justFilled;
  final int stepNumber; // 1-4
  final bool showConfetti;
  final VoidCallback onContinue;

  const OnboardingGauntletEquipScreen({
    super.key,
    required this.state,
    required this.justFilled,
    required this.stepNumber,
    this.showConfetti = false,
    required this.onContinue,
  });

  @override
  State<OnboardingGauntletEquipScreen> createState() => _OnboardingGauntletEquipScreenState();
}

class _OnboardingGauntletEquipScreenState extends State<OnboardingGauntletEquipScreen> {
  ConfettiController? _confettiController;
  bool _showCard = false;

  bool get _isFirstEquip => widget.stepNumber == 1;

  static const _funFacts = [ // 👈 new
    'Fun fact #1 — In USA, people spend about 12 hours a day on screens.',
    'Fun fact #2 — A 2025 meta-analysis of 15 studies involving 35,223 people found a positive correlation between ADHD symptoms and problematic social-media use',
    'Fun fact #3 — Neurodivergent people are 5x more likely to get distracted and get lost on their phone',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.showConfetti) {
      _confettiController = ConfettiController(duration: const Duration(seconds: 2));
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _confettiController?.play();
      });
    }

    if (_isFirstEquip) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _showCard = true);
      });
    } else {
      _showCard = true;
    }
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  String get _formattedStartTime {
    final t = widget.state.startTime;
    if (t == null) return '--:--';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (_confettiController != null)
            ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [Color(0xFFEE8FA8), Color(0xFF7FB4E8), Color(0xFF7FC9BB), Color(0xFFB398E8), Color(0xFFF8D35A)],
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  if (!widget.showConfetti) ...[ // 👈 unchanged flow for steps 1-3
                    const Spacer(),
                    Text(
                      '${widget.stepNumber}/4 steps done',
                      style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _funFacts[(widget.stepNumber - 1).clamp(0, _funFacts.length - 1)],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _isFirstEquip
                        ? (_showCard
                        ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        final dy = (1 - value) * -200;
                        return Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Transform.translate(offset: Offset(0, dy), child: child),
                        );
                      },
                      child: ScheduleGauntletCard(state: widget.state, justFilled: widget.justFilled),
                    )
                        : const SizedBox(height: 140))
                        : ScheduleGauntletCard(state: widget.state, justFilled: widget.justFilled),
                    const SizedBox(height: 28),
                    ScheduleGauntletStones(state: widget.state, justFilled: widget.justFilled, isFinalStone: widget.showConfetti),
                    const Spacer(),
                    OnboardingContinueButton(label: 'Continue', onTap: widget.onContinue),
                  ] else ...[ // 👈 new — final screen merges "Schedule complete!" with the old confirmation content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              'Schedule complete! 🎉',
                              style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 26, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 24),
                            ScheduleGauntletStones(state: widget.state, justFilled: widget.justFilled, isFinalStone: true),
                            const SizedBox(height: 28),
                            Text(
                              'Your apps will block at',
                              style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formattedStartTime,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF4A3728),
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _stepIcon(Icons.schedule_rounded, 'Schedule\nstarts'),
                                _arrow(),
                                _stepIcon(Icons.block_rounded, 'Apps\nblocked'),
                                _arrow(),
                                _stepIcon(Icons.lock_open_rounded, 'Schedule\nends'),
                              ],
                            ),
                            const SizedBox(height: 16),

                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Your schedule outlook',
                                    style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Complete your block session on these\ndays to stay consistent',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 12.5, height: 1.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(7, (i) {
                                      const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                      const dayColors = [ // 👈 new — one pastel per weekday position
                                        Color(0xFFEE8FA8), // pink
                                        Color(0xFF7FB4E8), // blue
                                        Color(0xFFF8D35A), // gold
                                        Color(0xFF7FC9BB), // teal
                                        Color(0xFFB398E8), // purple
                                        Color(0xFFEDA574), // peach
                                        Color(0xFFEE8FA8), // pink (repeats for Sunday)
                                      ];
                                      const dayTextColors = [ // 👈 new — matching darker text color per pastel, for contrast
                                        Color(0xFF8A3D54),
                                        Color(0xFF0F4A72),
                                        Color(0xFF7A5A0A),
                                        Color(0xFF0F4A32),
                                        Color(0xFF4A2E7A),
                                        Color(0xFF7A3F14),
                                        Color(0xFF8A3D54),
                                      ];
                                      final isActive = widget.state.days.contains(i);
                                      return Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive ? dayColors[i] : const Color(0xFFFFF7ED), // 👈 was solid #7DD3B0
                                          border: Border.all(
                                            color: isActive ? dayColors[i] : const Color(0xFFF0E6D8),
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            dayLabels[i],
                                            style: GoogleFonts.poppins(
                                              color: isActive ? dayTextColors[i] : const Color(0xFFB08A5A), // 👈 was #0F4A32 for all active
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OnboardingContinueButton(label: 'Finish', onTap: widget.onContinue),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
          ),
          child: Icon(icon, color: const Color(0xFF4A3728), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 11, height: 1.3),
        ),
      ],
    );
  }

  Widget _arrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.arrow_forward_rounded, color: const Color(0xFFB08A5A).withValues(alpha: 0.5), size: 16),
    );
  }
}