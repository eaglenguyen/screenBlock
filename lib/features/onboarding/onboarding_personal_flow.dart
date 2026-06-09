import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/onboarding_stats.dart';
import 'onboarding_animations.dart';
import 'onboarding_chat_screen.dart';
import 'onboarding_demo_screens.dart';
import 'onboarding_viewmodel.dart';





// ── Screen 1 — Age Range ──────────────────────────────

class OnboardingAgeScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(int age) onSelected;

  const OnboardingAgeScreen({
    super.key,
    required this.onBack,
    required this.onSelected,
  });

  @override
  State<OnboardingAgeScreen> createState() =>
      _OnboardingAgeScreenState();
}

class _OnboardingAgeScreenState extends State<OnboardingAgeScreen>
    with SingleTickerProviderStateMixin {

  String? _selected;


  final List<Map<String, dynamic>> _options = [
    {'label': 'Under 18', 'age': 16},
    {'label': '18 – 24', 'age': 21},
    {'label': '25 – 34', 'age': 29},
    {'label': '35 – 44', 'age': 39},
    {'label': '45+', 'age': 50},
  ];

  @override
  Widget build(BuildContext context) {
    return _StatsShell(
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          Text(
            'How old are you?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "We'll use this to personalize\nyour results",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          ..._options.map((opt) {
            final isSelected = _selected == opt['label'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selected = opt['label'] as String);
                  Future.delayed(const Duration(milliseconds: 250), () {
                    widget.onSelected(opt['age'] as int);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEDB82A).withValues(alpha: 0.12)
                        : const Color(0xFF1E1E35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEDB82A).withValues(alpha: 0.6)
                          : const Color(0xFF2A2A48),
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        opt['label'] as String,
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? const Color(0xFFEDB82A)
                              : Colors.white,
                          fontSize: 17,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        _AnimatedCheck(),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }
}

// ── Screen 2 — Hours Question ─────────────────────────

class OnboardingHoursScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(double hours) onSelected;

  const OnboardingHoursScreen({
    super.key,
    required this.onBack,
    required this.onSelected,
  });

  @override
  State<OnboardingHoursScreen> createState() =>
      _OnboardingHoursScreenState();
}

class _OnboardingHoursScreenState extends State<OnboardingHoursScreen> {
  String? _selected;

  final List<Map<String, dynamic>> _options = [
    {'label': '1 – 2 hours', 'hours': 1.5},
    {'label': '3 – 4 hours', 'hours': 3.5},
    {'label': '5 – 6 hours', 'hours': 5.5},
    {'label': '7+ hours', 'hours': 8.0},
  ];

  @override
  Widget build(BuildContext context) {
    return _StatsShell(
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          Text(
            'How many hours do you\nspend on your phone\ndaily?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Be honest — no judgment here 😅',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 40),
          ..._options.map((opt) {
            final isSelected = _selected == opt['label'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selected = opt['label'] as String);
                  Future.delayed(const Duration(milliseconds: 250), () {
                    widget.onSelected(opt['hours'] as double);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEDB82A).withValues(alpha: 0.12)
                        : const Color(0xFF1E1E35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEDB82A).withValues(alpha: 0.6)
                          : const Color(0xFF2A2A48),
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        opt['label'] as String,
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? const Color(0xFFEDB82A)
                              : Colors.white,
                          fontSize: 17,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected) _AnimatedCheck(),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }
}

// ── Screen 3 — Bad News Stats ─────────────────────────

class OnboardingBadNewsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final OnboardingStatsData data;

  const OnboardingBadNewsScreen({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.data,
  });

  @override
  State<OnboardingBadNewsScreen> createState() =>
      _OnboardingBadNewsScreenState();
}

class _OnboardingBadNewsScreenState
    extends State<OnboardingBadNewsScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late List<Animation<double>> _fades;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fades = List.generate(5, (i) {
      final start = i * 0.15;
      final end = (start + 0.3).clamp(0.0, 1.0);
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
    final d = widget.data;
    final yearsLost = d.yearsLostTotal.round();

    return _StatsShell(
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // headline
          FadeTransition(
            opacity: _fades[0],
            child: Text(
              "That's a lot of time...",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // big number
          FadeTransition(
            opacity: _fades[1],
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${d.hoursPerDay.toStringAsFixed(1)}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFEDB82A),
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                  TextSpan(
                    text: ' hrs/day',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // stat rows
          FadeTransition(
            opacity: _fades[2],
            child: _statRow(
              label: 'Hours per year',
              value: '${(d.hoursPerDay * 365).round().toString()} hrs',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _fades[3],
            child: _statRow(
              label: 'Days per year',
              value: '${(d.hoursPerDay * 365 / 24).toStringAsFixed(1)} days',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _fades[4],
            child: _statRow(
              label: 'Years lost by age 80',
              value: '$yearsLost years',
              color: const Color(0xFFE74C3C),
              large: true,
            ),
          ),
          const SizedBox(height: 20),

          FadeTransition(
            opacity: _fades[4],
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              child: Text(
                'Based on an average lifespan of 80 years, '
                    'you will spend $yearsLost years of your life '
                    'staring at a screen.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),

          const Spacer(),

          _GoldButton(label: 'Show me', onTap: widget.onNext),
        ],
      ),
    );
  }

  Widget _statRow({
    required String label,
    required String value,
    required Color color,
    bool large = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A48), width: 0.5),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: large ? 20 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Screen 4 — Life Grid ──────────────────────────────

class OnboardingLifeGridScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final OnboardingStatsData data;

  const OnboardingLifeGridScreen({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.data,
  });

  @override
  State<OnboardingLifeGridScreen> createState() =>
      _OnboardingLifeGridScreenState();
}

class _OnboardingLifeGridScreenState
    extends State<OnboardingLifeGridScreen> {

  // 0 = white, 1 = blue (lived), 2 = red (lost)
  final List<int> _iconStates = List.filled(80, 0);
  bool _animationDone = false;

  @override
  void initState() {
    super.initState();
    _runAnimation();
  }

  Future<void> _runAnimation() async {
    final age = widget.data.age;
    final yearsLost = widget.data.yearsLostTotal.round().clamp(1, 40);

    // phase 1 — fill blue icons (years lived) one by one
    for (int i = 0; i < age && i < 80; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() => _iconStates[i] = 1);
      HapticFeedback.lightImpact();
    }

    await Future.delayed(const Duration(milliseconds: 400));

    // phase 2 — fill red icons from end (years lost) one by one
    for (int i = 0; i < yearsLost; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      final index = 79 - i;
      setState(() => _iconStates[index] = 2);
      HapticFeedback.mediumImpact();
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _animationDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final yearsLost = widget.data.yearsLostTotal.round().clamp(1, 40);

    return _StatsShell(
      onBack: widget.onBack,
      child: Column(
        children: [
          const SizedBox(height: 24),

          Text(
            'Your life in years',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Each icon = 1 year of your life',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // 8×10 grid
          AspectRatio(
            aspectRatio: 8 / 10,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 80,
              itemBuilder: (context, i) {
                final state = _iconStates[i];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: _PersonIcon(state: state),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(const Color(0xFF3B82F6), 'Years lived'),
              const SizedBox(width: 20),
              _legendItem(Colors.white.withValues(alpha: 0.3), 'Remaining'),
              const SizedBox(width: 20),
              _legendItem(const Color(0xFFE74C3C), 'Lost to phone'),
            ],
          ),

          const SizedBox(height: 16),

          // caption — shows after animation
          AnimatedOpacity(
            opacity: _animationDone ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              child: Text(
                '$yearsLost years of your life lost to scrolling',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFE74C3C),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          AnimatedOpacity(
            opacity: _animationDone ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: _GoldButton(
              label: 'But there\'s good news →',
              onTap: widget.onNext,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Person icon widget ────────────────────────────────

class _PersonIcon extends StatelessWidget {
  final int state; // 0=white, 1=blue, 2=red

  const _PersonIcon({required this.state});

  Color get color {
    switch (state) {
      case 1: return const Color(0xFF3B82F6);
      case 2: return const Color(0xFFE74C3C);
      default: return Colors.white.withValues(alpha: 0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      child: Icon(
        Icons.person_rounded, // 👈 built-in Flutter icon
        color: color,
        size: 28,
      ),
    );
  }
}


// ── Screen 5 — Good News ──────────────────────────────

class OnboardingGoodNewsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final OnboardingStatsData data;

  const OnboardingGoodNewsScreen({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.data,
  });

  @override
  State<OnboardingGoodNewsScreen> createState() =>
      _OnboardingGoodNewsScreenState();
}

class _OnboardingGoodNewsScreenState
    extends State<OnboardingGoodNewsScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late List<Animation<double>> _fades;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fades = List.generate(4, (i) {
      final start = i * 0.18;
      final end = (start + 0.35).clamp(0.0, 1.0);
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
    final d = widget.data;
    final yearsSaved = d.yearsSavedIfHalved;
    final reducedHours = d.hoursPerDay / 2;

    return _StatsShell(
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          FadeTransition(
            opacity: _fades[0],
            child: Text(
              'But here\'s the\ngood news 🌱',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 32),

          FadeTransition(
            opacity: _fades[1],
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Cut down to just',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                          '${reducedHours.toStringAsFixed(1)}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF4CAF50),
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                        TextSpan(
                          text: ' hrs/day',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          FadeTransition(
            opacity: _fades[2],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2A2A48), width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'You get back',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    d.formatYears(yearsSaved),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4CAF50),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          FadeTransition(
            opacity: _fades[3],
            child: Text(
              'ScreenBlock helps you get there —\none blocked session at a time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),

          const Spacer(),

          _GoldButton(
            label: "Let's get started →",
            onTap: widget.onNext,
          ),
        ],
      ),
    );
  }
}

// ── Shared shell ──────────────────────────────────────

class _StatsShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onBack;

  const _StatsShell({required this.child, required this.onBack});

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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onBack();
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared gold button ────────────────────────────────

class _GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GoldButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEDB82A),
          foregroundColor: const Color(0xFF1A1208),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }
}

// ── Animated checkmark ────────────────────────────────

class _AnimatedCheck extends StatefulWidget {
  @override
  State<_AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<_AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFFEDB82A),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF1A1208),
          size: 15,
        ),
      ),
    );
  }
}
