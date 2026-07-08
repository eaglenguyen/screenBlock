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
  final double screenTimeGoalHours;
  final List<String> selectedGoals;
  final String futureVision;
  final bool isHighCommitment;
  final VoidCallback onNext;

  const OnboardingSnapshotScreen({
    super.key,
    required this.userName,
    required this.age,
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
    extends ConsumerState<OnboardingSnapshotScreen> {
  late bool _selectedDark;

  @override
  void initState() {
    super.initState();
    final themeMode = ref.read(themeProvider);
    _selectedDark = themeMode == ThemeMode.dark;
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
    final themeMode = ref.watch(themeProvider); // 👈 watch — rebuilds live on switch
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
                            Text(
                              'your personalized plan',
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary(context),
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'based on your answers, here is your profile!',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary(context),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── profile card ──────────
                            _SnapshotCard(
                              context: context,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.gold(context).withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            widget.userName.isNotEmpty
                                                ? widget.userName[0].toUpperCase()
                                                : '?',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.gold(context),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.userName,
                                            style: GoogleFonts.poppins(
                                              color: AppColors.textPrimary(context),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'Age: ${widget.age}',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.textSecondary(context),
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.only(top: 10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: AppColors.border(context),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Daily block goal',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.textPrimary(context),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,

                                          ),
                                        ),
                                        Text(
                                          '${widget.screenTimeGoalHours.toStringAsFixed(1)}h / day',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.gold(context),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── goals + vision card ────
                            _SnapshotCard(
                              context: context,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🎯  Your goals',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary(context),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: widget.selectedGoals.map((goal) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold(context).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.gold(context).withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          goal,
                                          style: GoogleFonts.poppins(
                                            color: AppColors.gold(context),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (widget.futureVision.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    // 👇 vision callout with left accent bar
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold(context).withOpacity(0.06),
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                        border: Border(
                                          left: BorderSide(
                                            color: AppColors.gold(context),
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'YOUR VISION',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.gold(context),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '"${widget.futureVision}"',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.textPrimary(context),
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── commitment card ────────
                            _SnapshotCard(
                              context: context,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('🔥', style: TextStyle(fontSize: 13)),
                                      const SizedBox(width: 7),
                                      Text(
                                        'Commitment level',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary(context),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _commitmentLabel,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.gold(context),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: _commitmentProgress),
                                      duration: const Duration(milliseconds: 900),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, _) {
                                        return LinearProgressIndicator(
                                          value: value,
                                          minHeight: 8,
                                          backgroundColor: AppColors.backgroundSubtle(context),
                                          valueColor: AlwaysStoppedAnimation(AppColors.gold(context)),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // 👇 low/high endpoint labels
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'low',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary(context).withOpacity(0.6),
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        'high',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary(context).withOpacity(0.6),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),


                            // ── theme picker ───────────
                            Text(
                              'Choose your look',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary(context),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Row(
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
                            const SizedBox(height: 16),

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
                                child: const Text('Continue →'),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: child,
    );
  }
}