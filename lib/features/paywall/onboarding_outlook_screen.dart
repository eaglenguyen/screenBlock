import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../onboarding/widgets/mascot_character.dart';

class OnboardingOutlookScreen extends StatefulWidget {
  final VoidCallback onNext;

  const OnboardingOutlookScreen({
    super.key,
    required this.onNext,
  });

  @override
  State<OnboardingOutlookScreen> createState() =>
      _OnboardingOutlookScreenState();
}

class _OnboardingOutlookScreenState extends State<OnboardingOutlookScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _cardAnims;

  final List<_WeekData> _weeks = [
    _WeekData(
      week: 'Week 1',
      title: 'Journey Begins',
      rivFile: 'assets/rive/mr_square_idlee.riv', // 👈 your actual filename
      color: const Color(0xFF1E2A3A),
      borderColor: const Color(0xFF2A4060),
      bullets: [
        'You start reaching for your phone less',
        'Your mental will feel better',
        'First signs of mental clarity',
      ],
    ),
    _WeekData(
      week: 'Week 2',
      title: 'The Changes',
      rivFile: 'assets/rive/mr_square_nod.riv', // 👈 your actual filename
      color: const Color(0xFF1A2A1A),
      borderColor: const Color(0xFF2A5030),
      bullets: [
        'Focusing feels more intense',
        'You stop procrastinating',
        'You start making better decisions',
      ],
    ),
    _WeekData(
      week: 'Week 3',
      title: 'The New You',
      rivFile: 'assets/rive/mr_square_yahoo.riv', // 👈 your actual filename

      color: const Color(0xFF2A2A1A),
      borderColor: const Color(0xFF504A20),
      bullets: [
        'You see a better version of yourself',
        'Become more intentional with your actions',
        'Life becomes more enjoyable',
      ],
    ),
    _WeekData(
      week: 'Week 4',
      title: 'Unstoppable Streak',
      rivFile: 'assets/rive/mr_square_fire.riv', // 👈 your actual filename
      color: const Color(0xFF2A1A2A),
      borderColor: const Color(0xFF50305A),
      bullets: [
        'You start doing more productive tasks',
        'You become more consistent',
        'Tasks are not dread as they use to be',
      ],
    ),
  ];



  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cardAnims = List.generate(_weeks.length, (i) {
      final start = i * 0.2;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          // gradient bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a0a3d),
                  Color(0xFF16162a),
                  Color(0xFF0a1a2a),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your first month\nwith pause now',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Here\'s what to expect week by week',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // scrollable cards
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: _weeks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final week = _weeks[i];
                      return AnimatedBuilder(
                        animation: _cardAnims[i],
                        builder: (_, child) => Opacity(
                          opacity: _cardAnims[i].value,
                          child: Transform.translate(
                            offset:
                            Offset(0, 20 * (1 - _cardAnims[i].value)),
                            child: child,
                          ),
                        ),
                        child: _WeekCard(data: week),
                      );
                    },
                  ),
                ),

                // bottom CTA — mimics the paywall style
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24, 16, 24,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E35),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // free trial row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252542),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFEDB82A)
                                .withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Free',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '7 days free',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white
                                        .withValues(alpha: 0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEDB82A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Color(0xFF1A1208), size: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // no payment note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded,
                              color: Color(0xFFEDB82A), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'No Payment Due Now!',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onNext();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEDB82A),
                            foregroundColor: const Color(0xFF1A1208),
                            padding:
                            const EdgeInsets.symmetric(vertical: 18),
                            shape: const StadiumBorder(),
                            elevation: 0,
                            textStyle: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('Try for \$0.00'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '7 days free, then \$19.99/year (\$1.67/month)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Week data model ───────────────────────────────────

class _WeekData {
  final String week;
  final String title;
  final Color color;
  final Color borderColor;
  final List<String> bullets;
  final String rivFile;

  const _WeekData({
    required this.week,
    required this.title,
    required this.color,
    required this.borderColor,
    required this.bullets,
    required this.rivFile
  });
}

// ── Week card ─────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  final _WeekData data;

  const _WeekCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.borderColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // mascot + week label
          Column(
            children: [
              MascotCharacter(size: 64, rivFile: data.rivFile,),
              const SizedBox(height: 4),
              Text(
                data.week,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  data.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                ...data.bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          )),
                      Expanded(
                        child: Text(
                          b,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trial Reminder Screen ─────────────────────────────

class OnboardingTrialReminderScreen extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingTrialReminderScreen({
    super.key,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a0a3d),
                  Color(0xFF16162a),
                  Color(0xFF0a1a2a),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),

                  // bell icon
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDB82A).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEDB82A).withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Text('🔔', style: TextStyle(fontSize: 44)),
                          ),
                        ),
                        // red notification dot
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE74C3C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // headline
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.3,
                      ),
                      children: [
                        const TextSpan(text: 'You\'ll get a reminder '),
                        TextSpan(
                          text: '2 day',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFEDB82A),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: '\nbefore your trial ends'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'All features are '),
                        TextSpan(
                          text: '7 days free',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFEDB82A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                        const TextSpan(text: ' so\nyou can start improving today'),
                      ],
                    ),
                  ),

                  const Spacer(flex: 4),

                  // next button
                  // no payment note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Color(0xFFEDB82A), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'No Payment Due Now!',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

// CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onNext();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEDB82A),
                        foregroundColor: const Color(0xFF1A1208),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const StadiumBorder(),
                        elevation: 0,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('continue for FREE'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '7 days free, then \$19.99/year (\$1.67/month)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}