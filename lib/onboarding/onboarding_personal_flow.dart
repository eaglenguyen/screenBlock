import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../../core/constants/hivebox_names.dart';
import '../../core/theme/theme.notifier.dart';
import 'data/onboarding_graph.dart';
import 'data/onboarding_stats.dart';



// Theme Picker


class OnboardingThemeScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const OnboardingThemeScreen({
    super.key,
    required this.onNext,
  });

  @override
  ConsumerState<OnboardingThemeScreen> createState() =>
      _OnboardingThemeScreenState();
}

class _OnboardingThemeScreenState
    extends ConsumerState<OnboardingThemeScreen> {
  bool _selectedDark = true;

  void _select(bool isDark) {
    HapticFeedback.lightImpact();
    setState(() => _selectedDark = isDark);
    if (isDark) {
      ref.read(themeProvider.notifier).setDark();
    } else {
      ref.read(themeProvider.notifier).setLight();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider); // 👈 watch
    final isDarkTheme = themeMode == ThemeMode.dark;
    const gold = Color(0xFFEDB82A);


    // 👇 background adapts to selected theme
    final bgColor = isDarkTheme ? const Color(0xFF16162A) : const Color(0xFFF5F5F0);
    final gradientColors = isDarkTheme
        ? const [Color(0xFF1a0a3d), Color(0xFF16162a), Color(0xFF0a1a2a)]
        : const [Color(0xFFF0EFE8), Color(0xFFF5F5F0), Color(0xFFEEEDE8)];

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // gradient bg
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // decorative circle
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: 0.04),
                border: Border.all(
                  color: gold.withValues(alpha: 0.07),
                  width: 0.5,
                ),
              ),
            ),
          ),
          // main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // headline
                Text(
                  'Choose your look',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: isDarkTheme ? Colors.white : const Color(0xFF1A1A1A),
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'You can always change this in settings\n',
                        style: GoogleFonts.poppins(
                          color: isDarkTheme
                              ? Colors.white.withValues(alpha: 0.45)
                              : const Color(0xFF666666),
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: 'Theme will show later in app',
                        style: GoogleFonts.poppins(
                          color: isDarkTheme
                              ? Colors.white.withValues(alpha: 0.35)
                              : const Color(0xFF888888),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // mockup cards row — fixed height
                Expanded(
                  child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ThemeOption(
                          isDark: true,
                          isSelected: _selectedDark,
                          onTap: () => _select(true),
                          label: 'Dark',
                          badge: 'recommended',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ThemeOption(
                          isDark: false,
                          isSelected: !_selectedDark,
                          onTap: () => _select(false),
                          label: 'Light',
                        ),
                      ),
                    ],
                  ),
                )
                ),

                const Spacer(),

                // confirm button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: const Color(0xFF1A1208),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const StadiumBorder(),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Confirm →'),
                    ),
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

// ── Theme option ──────────────────────────────────────
class ThemeOption extends StatelessWidget {
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;
  final String? badge;

  const ThemeOption({
    super.key,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
    required this.label,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFEDB82A);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // phone mockup with fixed height
          Expanded(
              child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? gold : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: gold.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: PhoneMockupContent(isDark: isDark),
            ),
          )
          ),
          const SizedBox(height: 14),

          // radio + label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? gold
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: isSelected ? gold : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF1A1208),
                  size: 11,
                )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? gold
                      : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF666666),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (badge != null) ...[
            const SizedBox(height: 2),
            Text(
              badge!,
              style: GoogleFonts.poppins(
                color: gold.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Phone mockup content ──────────────────────────────
class PhoneMockupContent extends StatelessWidget {
  final bool isDark;

  const PhoneMockupContent({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F0);
    final cardBg = isDark ? const Color(0xFF252525) : const Color(0xFFFFFFFF);
    final subtle = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEEEDE8);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF888888);
    final borderColor =
    isDark ? const Color(0xFF333333) : const Color(0xFFDDDDD8);
    const gold = Color(0xFFEDB82A);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // mock header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: subtle,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '49 ⭐️',
                  style: TextStyle(
                    color: gold,
                    fontSize: 6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // timer card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Time Blocked Today',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['00', '04', '59'].expand((t) sync* {
                    yield Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: subtle,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor, width: 0.5),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: subColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                    if (t != '59') {
                      yield Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(':',
                            style:
                            TextStyle(color: borderColor, fontSize: 8)),
                      );
                    }
                  }).toList(),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      '▶  Block Now',
                      style: TextStyle(
                        color: Color(0xFF1A1208),
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // second card
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 3,
                        width: 30,
                        decoration: BoxDecoration(
                          color: subColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
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

// ── Screen 1 — Age Range ──────────────────────────────

class OnboardingAgeScreen extends StatefulWidget {
  final Function(int age) onSelected;

  const OnboardingAgeScreen({
    super.key,
    required this.onSelected,
  });

  @override
  State<OnboardingAgeScreen> createState() => _OnboardingAgeScreenState();
}

class _OnboardingAgeScreenState extends State<OnboardingAgeScreen> {
  final TextEditingController _ctrl = TextEditingController();
  int? _parsedAge;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final val = int.tryParse(_ctrl.text.trim());
      setState(() {
        _parsedAge = (val != null && val >= 16 && val <= 80) ? val : null;
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // years remaining based on 80 year lifespan
  int get _yearsRemaining => _parsedAge != null
      ? (80 - _parsedAge!).clamp(0, 80)
      : 0;

  @override
  Widget build(BuildContext context) {
    return _StatsShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 140),
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
          const SizedBox(height: 8),
          Text(
            "We'll use this to personalize\nyour results",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // age input
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF252542),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _parsedAge != null
                    ? const Color(0xFFEDB82A).withValues(alpha: 0.5)
                    : const Color(0xFF2A2A48),
                width: _parsedAge != null ? 1.5 : 0.5,
              ),
              boxShadow: _parsedAge != null
                  ? [
                BoxShadow(
                  color: const Color(0xFFEDB82A).withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
                  : null,
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 2,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your age (16-80)',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                counterText: '', // hides maxLength counter
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) {
                if (_parsedAge != null) widget.onSelected(_parsedAge!);
              },
            ),
          ),

          // personalized preview — shows after valid age entered

          const SizedBox(height: 24),


          // continue button
          AnimatedOpacity(
            opacity: _parsedAge != null ? 1.0 : 0.35,
            duration: const Duration(milliseconds: 200),
            child: _GoldButton(
              label: 'Continue →',
              onTap: _parsedAge != null
                  ? () {
                HapticFeedback.lightImpact();
                FocusScope.of(context).unfocus(); // 👈 dismiss keyboard first
                widget.onSelected(_parsedAge!);
              }
                  : () {},
            ),
          ),
        ],
      ),
    );
  }
}


class OnboardingScreenTimeGoalScreen extends StatefulWidget {
  final Function(int hours) onSelected;

  const OnboardingScreenTimeGoalScreen({
    super.key,
    required this.onSelected,
  });

  @override
  State<OnboardingScreenTimeGoalScreen> createState() =>
      _OnboardingScreenTimeGoalScreenState();
}

class _OnboardingScreenTimeGoalScreenState
    extends State<OnboardingScreenTimeGoalScreen> {
  int? _selectedHours;

  final List<Map<String, dynamic>> _options = [
    {'hours': 1, 'label': '1 hour blocked', 'sub': 'A solid start', 'emoji': '🌱'},
    {'hours': 2, 'label': '2 hours blocked', 'sub': 'Building momentum', 'emoji': '📈', 'recommended': true}, // 👈 new
    {'hours': 3, 'label': '3 hours blocked', 'sub': 'Serious focus', 'emoji': '🎯'},
    {'hours': 4, 'label': '4 hours blocked', 'sub': 'Deep work mode', 'emoji': '⚡'},
    {'hours': 5, 'label': '5 hours blocked', 'sub': 'Maximum discipline', 'emoji': '🏆'},
  ];

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
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEDB82A).withValues(alpha: 0.04),
                border: Border.all(
                  color: const Color(0xFFEDB82A).withValues(alpha: 0.07),
                  width: 0.5,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // headline
                  Text(
                    'Set your daily\nblocking goal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How many hours do you want\nto block distracting apps each day?',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // options
                  Expanded(
                    child: ListView.separated(
                      itemCount: _options.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final opt = _options[i];
                        final isSelected = _selectedHours == opt['hours'];

                        return GestureDetector(
                          onTap:  () async {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedHours = opt['hours']);

                            // 👇 save to Hive
                            final box = Hive.box(HiveBoxNames.settings);
                            await box.put(HiveBoxNames.blockingGoalHours, opt['hours']);

                            Future.delayed(
                              const Duration(milliseconds: 300),
                                  () => widget.onSelected(opt['hours']),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEDB82A)
                                  .withValues(alpha: 0.1)
                                  : const Color(0xFF1E1E35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFEDB82A)
                                    .withValues(alpha: 0.6)
                                    : const Color(0xFF2A2A48),
                                width: isSelected ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(opt['emoji'], style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            opt['label'],
                                            style: GoogleFonts.poppins(
                                              color: isSelected ? const Color(0xFFEDB82A) : Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (opt['recommended'] == true) ...[ // 👈 new
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                'Recommended',
                                                style: GoogleFonts.poppins(
                                                  color: const Color(0xFFEDB82A),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        opt['sub'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEDB82A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF1A1208),
                                      size: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      // 👇 save default
                      final box = Hive.box(HiveBoxNames.settings);
                      await box.put(HiveBoxNames.blockingGoalHours, 2);
                      widget.onSelected(2);
                    },
                    child: Text(
                      'Skip for now',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
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
            'How many hours do you spend on your phone daily?',
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
                      if (isSelected) _AnimatedCheck(),
                    ],
                  ),
                ),
              ),
            );
          }),
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
  final String userName;

  const OnboardingBadNewsScreen({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.data,
    this.userName = '',
  });

  @override
  State<OnboardingBadNewsScreen> createState() =>
      _OnboardingBadNewsScreenState();
}

class _OnboardingBadNewsScreenState
    extends State<OnboardingBadNewsScreen>
    with TickerProviderStateMixin {

  // ── Loading phase ─────────────────────────────────
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String _loadingLabel = 'Gathering your data...';

  late AnimationController _loadingCtrl;

  static const _loadingSteps = [
    (0.0,  'Gathering your data...'),
    (0.50, 'Calculating screen time...'),
    (0.90, 'Results ready'),
  ];

  // ── Stats phase ───────────────────────────────────
  late AnimationController _statsCtrl;
  late List<Animation<double>> _fades;

  @override
  void initState() {
    super.initState();

    // loading controller
    _loadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _loadingCtrl.addListener(() {
      final curve = Curves.easeInOut;
      final curved = curve.transform(_loadingCtrl.value);
      setState(() {
        _loadingProgress = curved;
        for (int i = _loadingSteps.length - 1; i >= 0; i--) {
          if (curved >= _loadingSteps[i].$1) {
            _loadingLabel = _loadingSteps[i].$2;
            break;
          }
        }
      });
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _loadingCtrl.forward();
    });

    _loadingCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _statsCtrl.forward();
        });
      }
    });

    // stats controller
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _fades = List.generate(6, (i) {
      final start = i * 0.18;  //
      final end = (start + 0.25).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _statsCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _loadingCtrl.forward();
  }

  @override
  void dispose() {
    _loadingCtrl.dispose();
    _statsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final yearsLost = d.yearsLostTotal.round();

    return _StatsShell(
      child: _isLoading
          ? _buildLoadingPhase()
          : _buildStatsPhase(d, yearsLost),
    );
  }

  // ── Loading UI ────────────────────────────────────
  Widget _buildLoadingPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),


        // icon
        Center(
          child: Image.asset(
            'assets/icons/square_notes_cutout.png',
            width: 140,
            height: 140,
          ),
        ),
        const SizedBox(height: 32),

        // headline
        Text(
          'Analyzing your\nhabits...',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Based on ${widget.data.hoursPerDay.toStringAsFixed(1)} hrs/day · age ${widget.data.age}',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 48),

        // progress bar track
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _loadingProgress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEDB82A), Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // label + percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _loadingLabel,
                key: ValueKey(_loadingLabel),
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '${(_loadingProgress * 100).round()}%',
              style: GoogleFonts.poppins(
                color: const Color(0xFFEDB82A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),


      ],
    );
  }

  // ── Stats UI ──────────────────────────────────────
  Widget _buildStatsPhase(OnboardingStatsData d, int yearsLost) {
    return SingleChildScrollView(
     child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),

        FadeTransition(
          opacity: _fades[0],
          child: Text(
            "That's a lot of time ${widget.userName}...",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),

        FadeTransition(
          opacity: _fades[1],
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: d.hoursPerDay.toStringAsFixed(1),
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

        FadeTransition(
          opacity: _fades[2],
          child: _statRow(
            label: 'Hours per year',
            value: '${(d.hoursPerDay * 365).round()} hrs',
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

        const SizedBox(height: 24),
        FadeTransition(
          opacity: _fades[5], // 👈 button is last
          child: _GoldButton(label: 'Show me more..', onTap: widget.onNext),
        ),      ],
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
  final VoidCallback onNext;
  final OnboardingStatsData data;

  const OnboardingLifeGridScreen({
    super.key,
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
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _iconStates[i] = 1);
      HapticFeedback.lightImpact();
    }

    await Future.delayed(const Duration(milliseconds: 600));

    // phase 2 — fill red icons from end (years lost) one by one
    for (int i = 0; i < yearsLost; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
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
      child: Column(
        children: [
          const SizedBox(height: 24),

          Text(
            'Your life is important',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
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


          const SizedBox(height: 16),

          // caption — shows after animation
          AnimatedOpacity(
            opacity: _animationDone ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(10),
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
              label: 'Show me the good news →',
              onTap: widget.onNext,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
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
        size: 20,
      ),
    );
  }
}


class OnboardingGoodNewsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final OnboardingStatsData data;
  final String userName;

  const OnboardingGoodNewsScreen({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.data,
    this.userName = '',
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
      duration: const Duration(milliseconds: 7000),
    );

    _fades = List.generate(5, (i) {
      final start = i * 0.22;
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

    return _StatsShell(
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 90),

          // "but here's the good news"
          FadeTransition(
            opacity: _fades[0],
            child: Text(
              '...but here\'s\nthe good news ${widget.userName}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // one session at a time message
          FadeTransition(
            opacity: _fades[1],
            child: Text(
              'With one blocked session at a time,\nwe can help you get back',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // big years back stat
          FadeTransition(
            opacity: _fades[2],
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: d.formatYears(yearsSaved),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFEDB82A),
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'of your life back',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),


          const Spacer(),

          FadeTransition(
            opacity: _fades[3], // 👈 last to appear
            child: _GoldButton(
              label: "Whats next? →",
              onTap: widget.onNext,
            ),
          ),
        ],
      ),
    );
  }
}

// Screen 6 - Graph

class OnboardingProductivityScreen extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingProductivityScreen({
    super.key,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _StatsShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          Text(
            'Your Plan is Ready',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'based on all of your answers,\nyou will start to see improvement within \n2 months',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          const ProductivityGraph(),
          const SizedBox(height: 40),
          _GoldButton(
            label: "Let's get started →",
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}
// ── Shared shell ──────────────────────────────────────

class _StatsShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;

  const _StatsShell({required this.child, this.onBack});

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
                  if (onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onBack!();
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
