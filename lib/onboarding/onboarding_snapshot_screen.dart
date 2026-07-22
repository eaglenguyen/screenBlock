import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../core/theme/theme.notifier.dart';
import 'onboarding_personal_flow.dart';

class OnboardingSnapshotScreen extends ConsumerStatefulWidget {
  final String userName;
  final int age;
  final double currentDailyHours;
  final double screenTimeGoalHours;
  final List<String> selectedGoals;
  final String futureVision;
  final bool isHighCommitment;
  final VoidCallback onNext;

  const OnboardingSnapshotScreen({
    super.key,
    required this.userName,
    required this.age,
    required this.currentDailyHours,
    required this.screenTimeGoalHours,
    required this.selectedGoals,
    required this.futureVision,
    required this.isHighCommitment,
    required this.onNext,
  });

  @override
  ConsumerState<OnboardingSnapshotScreen> createState() =>
      _OnboardingSnapshotScreenState();
}

class _OnboardingSnapshotScreenState
    extends ConsumerState<OnboardingSnapshotScreen>
    with SingleTickerProviderStateMixin {
  late bool _selectedDark;
  late AnimationController _entranceCtrl;

  // 👇 one entry per top-level block that should fade/slide in
  static const int _blockCount = 7;
  // 0: header text, 1: profile card, 2: goals card, 3: commitment card,
  // 4: theme label, 5: theme row, 6: button
  late final List<Animation<double>> _blockAnims;

  final List<Map<String, String>> _allGoals = [
    {'emoji': '🧘', 'title': 'More Mindful'},
    {'emoji': '📵', 'title': 'More time offline'},
    {'emoji': '⚡', 'title': 'Be more productive'},
    {'emoji': '📱', 'title': 'Reduce social media'},
    {'emoji': '🔄', 'title': 'Build better habits'},
  ];

  String? _getEmoji(String title) {
    try {
      return _allGoals.firstWhere((g) => g['title'] == title)['emoji'];
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final themeMode = ref.read(themeProvider);
    _selectedDark = themeMode == ThemeMode.dark;

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + _blockCount * 220), // 👈 scales with block count
    );

    _blockAnims = List.generate(_blockCount, (i) {
      final start = (i * 0.13).clamp(0.0, 0.85);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // 👇 wraps a block in fade + slide-up, driven by its own Interval slot
  Widget _animatedBlock(int index, Widget child) {
    final anim = _blockAnims[index];
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  void _selectTheme(bool isDark) {
    HapticFeedback.lightImpact();
    setState(() => _selectedDark = isDark);
    if (isDark) {
      ref.read(themeProvider.notifier).setDark();
    } else {
      ref.read(themeProvider.notifier).setLight();
    }
  }

  double get _commitmentProgress => widget.isHighCommitment ? 0.90 : 0.25;
  String get _commitmentLabel => widget.isHighCommitment ? '90%' : '25%';

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkTheme = themeMode == ThemeMode.dark;

    final bgColor = isDarkTheme ? const Color(0xFF16162A) : const Color(0xFFF5F5F0);
    final gradientColors = isDarkTheme
        ? const [Color(0xFF1a0a3d), Color(0xFF16162a), Color(0xFF0a1a2a)]
        : const [Color(0xFFF0EFE8), Color(0xFFF5F5F0), Color(0xFFEEEDE8)];

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── block 0: header ──
                            _animatedBlock(
                              0,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Profile',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textPrimary(context),
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Based on your answers, here\'s where you\'re at',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary(context),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── block 1: profile card (hero) — diagonal split ──
                            _animatedBlock(
                              1,
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(minHeight: 100), // 👈 add this
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundCard(context),
                                    borderRadius: BorderRadius.circular(18), // 👈 add this — matches ClipRRect's radius
                                    border: Border.all(
                                      color: AppColors.gold(context).withOpacity(0.5),
                                      width: 1.5,
                                    ),                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipPath(
                                          clipper: _DiagonalClipper(),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.transparent,
                                                  AppColors.gold(context).withOpacity(0.14),
                                                ],
                                                stops: const [0.0, 0.7],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    widget.userName,
                                                    style: GoogleFonts.poppins(
                                                      color: AppColors.textPrimary(context),
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: -0.5,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Age ${widget.age}',
                                                    style: GoogleFonts.poppins(
                                                      color: AppColors.textSecondary(context),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'DAILY BLOCK GOAL',
                                                  style: GoogleFonts.poppins(
                                                    color: AppColors.gold(context).withOpacity(0.7),
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                Text(
                                                  '${widget.screenTimeGoalHours.toStringAsFixed(1)}h',
                                                  style: GoogleFonts.poppins(
                                                    color: AppColors.gold(context),
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── block 2: commitment card ──
                            _animatedBlock(
                              2,
                              _SnapshotCard(
                                context: context,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: AppColors.gold(context),
                                            borderRadius: BorderRadius.circular(9),
                                          ),
                                          child: const Center(
                                            child: Text('🔥', style: TextStyle(fontSize: 15)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Commitment level',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.textPrimary(context),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _commitmentLabel,
                                          style: GoogleFonts.poppins(
                                            color: AppColors.gold(context),
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 11),
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0, end: _commitmentProgress),
                                            duration: const Duration(milliseconds: 900),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, value, _) {
                                              return LinearProgressIndicator(
                                                value: value,
                                                minHeight: 22,
                                                backgroundColor:
                                                AppColors.backgroundSubtle(context),
                                                valueColor:
                                                AlwaysStoppedAnimation(AppColors.gold(context)),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'low',
                                                  style: GoogleFonts.poppins(
                                                    color: AppColors.textPrimary(context)
                                                        .withOpacity(0.7),
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  'high',
                                                  style: GoogleFonts.poppins(
                                                    color: widget.isHighCommitment
                                                        ? const Color(0xFF1A1208)
                                                        : AppColors.textPrimary(context)
                                                        .withOpacity(0.7),
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

// ── block 3: goals + vision card ──
                            _animatedBlock(
                              3,
                              _SnapshotCard(
                                context: context,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const SizedBox(width: 7),
                                        Text(
                                          'what you want',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.textSecondary(context),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      children: widget.selectedGoals.map((goal) {
                                        final emoji = _getEmoji(goal);
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.withOpacity(0.2),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                if (emoji != null) ...[
                                                  Text(emoji, style: const TextStyle(fontSize: 15)),
                                                  const SizedBox(width: 10),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    goal,
                                                    style: GoogleFonts.poppins(
                                                      color: AppColors.textSecondary(context),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    if (widget.futureVision.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 11),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    AppColors.gold(context).withOpacity(0.15),
                                                    AppColors.gold(context).withOpacity(0.04),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: AppColors.gold(context).withOpacity(0.5),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.gold(context).withOpacity(0.15),
                                                    blurRadius: 14,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  '"${widget.futureVision}"',
                                                  style: GoogleFonts.poppins(
                                                    color: AppColors.textPrimary(context),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle: FontStyle.italic,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: -11,
                                              left: 14,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.gold(context),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '✨ YOUR VISION',
                                                  style: GoogleFonts.poppins(
                                                    color: const Color(0xFF1A1208),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── block 4: theme label ──
                            _animatedBlock(
                              4,
                              Row(
                                children: [
                                  Text(
                                    'Choose your theme',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary(context),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ── block 5: theme row ──
                            Expanded(
                              child: _animatedBlock(
                                5,
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ThemeOption(
                                        isDark: true,
                                        isSelected: _selectedDark,
                                        onTap: () => _selectTheme(true),
                                        label: 'Dark',
                                        badge: 'recommended',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ThemeOption(
                                        isDark: false,
                                        isSelected: !_selectedDark,
                                        onTap: () => _selectTheme(false),
                                        label: 'Light',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── block 6: button ──
                            _animatedBlock(
                              6,
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: widget.onNext,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold(context),
                                    foregroundColor: const Color(0xFF1A1208),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                    textStyle: GoogleFonts.poppins(
                                        fontSize: 17, fontWeight: FontWeight.w800),
                                  ),
                                  child: const Text('Save and Continue  →'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final Widget child;
  final BuildContext context;
  const _SnapshotCard({required this.context, required this.child});

  @override
  Widget build(BuildContext _) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold(context).withOpacity(0.35), width: 1),
      ),
      child: child,
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // starts the diagonal at 58% across the top, ends at 100% across the bottom
    path.moveTo(size.width * 0.58, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.28, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}