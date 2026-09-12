import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pausenow/onboarding/widgets/bouncing_arrow.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class ManualBlockingTutorial extends StatefulWidget {
  final VoidCallback onComplete;
  final bool showSkip;
  const ManualBlockingTutorial({
    super.key,
    required this.onComplete,
    this.showSkip = false,
  });
  @override
  State<ManualBlockingTutorial> createState() =>
      _ManualBlockingTutorialState();
}

class _ManualBlockingTutorialState extends State<ManualBlockingTutorial> {
  int _step = 0;
  void _next() {
    HapticFeedback.lightImpact();
    if (_step >= 4) {
      widget.onComplete();
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _ManualStep2BlockMode(
          key: const ValueKey('manual2'),
          onNext: _next,
          showSkip: widget.showSkip,
          onSkip: widget.onComplete,
        );
      case 1:
        return _ManualStep3AppPicker(
          key: const ValueKey('manual3'),
          onNext: _next,
        );
      case 2:
        return _ManualStep4Timer(
          key: const ValueKey('manual4'),
          onNext: _next,
        );
      case 3:
        return _ManualStep1HomeScreen(
          key: const ValueKey('manual1'),
          onNext: _next,
        );
      case 4:
        return _ManualStep5ClaimStars(
          key: const ValueKey('manual5'),
          onNext: _next,
        );
      default:
        widget.onComplete();
        return const SizedBox.shrink();
    }
  }
}

class _ManualStep1HomeScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _ManualStep1HomeScreen({
    super.key,
    required this.onNext,
  });
  @override
  Widget build(BuildContext context) {
    return _TutorialShell(
      child: Column(
        children: [
          const SizedBox(height: 32),
          const _StepLabel(step: 4),
          const SizedBox(height: 8),
          Text(
            'Start your blocking!',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The longer your block session,\nthe more ⭐️ you gain!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const TutorialPhoneMockup(
            child: _HomeScreenMockup(),
          ),
          const SizedBox(height: 24),
          const Expanded(child: SizedBox()),
          _TutorialButton(label: 'Next', onTap: onNext),
        ],
      ),
    );
  }
}

class _ManualStep2BlockMode extends StatelessWidget {
  final VoidCallback onNext;
  final bool showSkip;
  final VoidCallback onSkip;
  const _ManualStep2BlockMode({
    super.key,
    required this.onNext,
    required this.showSkip,
    required this.onSkip,
  });
  @override
  Widget build(BuildContext context) {
    return _TutorialShell(
      child: Column(
        children: [
          const Expanded(child: SizedBox()),
          const _StepLabel(step: 1),
          const SizedBox(height: 8),
          Text(
            'Choose your block mode',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.border(context), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: SizedBox(
                  height: 220,
                  child: _BlockModeSheetMockup(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Expanded(child: SizedBox()),
          _TutorialButton(label: 'Next', onTap: onNext),
          if (showSkip) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onSkip,
              child: Text(
                'Skip tutorial',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManualStep3AppPicker extends StatelessWidget {
  final VoidCallback onNext;
  const _ManualStep3AppPicker({super.key, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return _TutorialShell(
      child: Column(
        children: [
          const Expanded(child: SizedBox()),
          const _StepLabel(step: 2),
          const SizedBox(height: 8),
          Text(
            'Choose the apps that you want blocked',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The most distracting apps are recommended',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          TutorialPhoneMockup(
            height: 250,
            width: 250,
            child: _AppPickerMockup(),
          ),
          const SizedBox(height: 60),
          const Expanded(child: SizedBox()),
          _TutorialButton(label: 'Next', onTap: onNext),
        ],
      ),
    );
  }
}

class _ManualStep4Timer extends StatelessWidget {
  final VoidCallback onNext;
  const _ManualStep4Timer({super.key, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return _TutorialShell(
      child: Column(
        children: [
          const Expanded(child: SizedBox()),
          const _StepLabel(step: 3),
          const SizedBox(height: 8),
          Text(
            'Set your focus time',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 28),
          TutorialPhoneMockup(
            height: 220,
            child: _TimerSheetMockup(),
          ),
          const SizedBox(height: 24),
          const Expanded(child: SizedBox()),
          _TutorialButton(label: 'Next', onTap: onNext),
        ],
      ),
    );
  }
}

class _ManualStep5ClaimStars extends StatelessWidget {
  final VoidCallback onNext;
  const _ManualStep5ClaimStars({super.key, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return _TutorialShell(
      child: Column(
        children: [
          const SizedBox(height: 32),
          const _StepLabel(step: 5),
          const SizedBox(height: 8),
          Text(
            'Claim your stars! ⭐️',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Once your session ends, tap Claim\nto collect the stars you earned!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          TutorialPhoneMockup(
            child: _ClaimStarsMockup(onClaimed: onNext),
          ),
          const SizedBox(height: 24),
          const Expanded(child: SizedBox()),
          GestureDetector(
            onTap: onNext,
            child: Text(
              'Finish',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context).withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final int step;
  const _StepLabel({required this.step});
  @override
  Widget build(BuildContext context) {
    return Text(
      '$step.',
      textAlign: TextAlign.center,
      style: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.textPrimary(context),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class TutorialPhoneMockup extends StatelessWidget {
  final Widget child;
  final double height;
  final double width;
  const TutorialPhoneMockup({
    super.key,
    required this.child,
    this.height = 476,
    this.width = 280,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border(context), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: child,
        ),
      ),
    );
  }
}

class _HomeScreenMockup extends StatelessWidget {
  const _HomeScreenMockup();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard(context),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_outline_rounded,
                    color: AppColors.textSecondary(context), size: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent(context).withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '10 ⭐️',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent(context),
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 150,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSubtle(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context), width: 0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time Blocked Today',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textPrimary(context),
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['00', '00', '00'].expand((t) sync* {
                    yield Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard(context),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(t,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    );
                    if (t != '00') yield const SizedBox(width: 3);
                  }).toList(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('🛡️ Specific Apps',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary(context), fontSize: 6),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('⏱ 3h',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary(context), fontSize: 6)),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '▶  Start',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accentText(context),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/appsLocked.png',
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockModeSheetMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text('Block Mode', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: AppColors.backgroundCard(context), borderRadius: BorderRadius.circular(20)),
                    child: Text('All Apps', textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context), fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: AppColors.accent(context), borderRadius: BorderRadius.circular(20)),
                    child: Text('Specific Apps', textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentText(context), fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Blocked Apps', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary(context), fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Only these apps will be blocked', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context), fontSize: 9)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary(context), size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppItem {
  final String name;
  final bool selected;
  final String? icon;
  final Color color;
  const _AppItem({
    required this.name,
    required this.selected,
    this.icon,
    required this.color,
  });
}

class _AppPickerMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark; // 👈 new
    final apps = [
      _AppItem(name: 'Instagram', selected: true,
          icon: 'assets/icons/instagram.svg', color: const Color(0xFFE1306C)),
      _AppItem(name: 'TikTok', selected: true,
          icon: 'assets/icons/tiktok.svg', color: isDark ? Colors.white : Colors.black), // 👈 was Colors.white unconditionally
      _AppItem(name: 'YouTube', selected: false,
          icon: 'assets/icons/youtube.svg', color: const Color(0xFFFF0000)),
      _AppItem(name: 'Twitter', selected: false,
          icon: 'assets/icons/twitter-x.svg', color: const Color(0xFF1DA1F2)),
    ];
    return Container(
      color: AppColors.backgroundCard(context),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cancel', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context), fontSize: 8)),
              Text('Select Apps',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary(context), fontSize: 10, fontWeight: FontWeight.w700)),
              Text('Save',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accent(context), fontSize: 8, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ...apps.map((app) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: app.selected ? AppColors.accent(context) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: app.selected ? AppColors.accent(context) : AppColors.border(context),
                      width: 1,
                    ),
                  ),
                  child: app.selected
                      ? Icon(Icons.check_rounded, color: AppColors.accentText(context), size: 8)
                      : null,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: app.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: app.icon != null
                      ? Center(
                    child: SvgPicture.asset(
                      app.icon!,
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(app.color, BlendMode.srcIn),
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 6),
                Text(app.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary(context), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          )),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.textSecondary(context), size: 10),
                const SizedBox(width: 4),
                Text('Search', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context), fontSize: 7)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerSheetMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard(context),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                          color: AppColors.border(context),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Text('Set Timer',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(
                    '3h',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.accent(context),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1h',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary(context), fontSize: 9)),
                      Text('5h',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary(context), fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(17, (i) {
                            final isMajor = i % 4 == 0;
                            return Container(
                              width: 1.2,
                              height: isMajor ? 22 : 12,
                              color: AppColors.textSecondary(context).withValues(alpha: isMajor ? 0.35 : 0.15),
                            );
                          }),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          color: AppColors.accent(context),
                        ),
                      ],
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

class _ClaimStarsMockup extends StatefulWidget {
  final VoidCallback onClaimed;
  const _ClaimStarsMockup({required this.onClaimed});
  @override
  State<_ClaimStarsMockup> createState() => _ClaimStarsMockupState();
}

class _ClaimStarsMockupState extends State<_ClaimStarsMockup> {
  bool _claimed = false;
  AudioPlayer? _audioPlayer;
  bool _showFloating = false;
  double _floatingOpacity = 0;
  double _floatingOffset = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer!.setAsset('assets/sounds/levelUp.mp3').then((_) {
      _audioPlayer!.setVolume(0.5);
    });
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _onClaimTap() async {
    if (_claimed) return;
    setState(() => _claimed = true);
    HapticFeedback.mediumImpact();

    try {
      await _audioPlayer?.seek(Duration.zero);
      _audioPlayer?.play();
    } catch (_) {}

    setState(() {
      _showFloating = true;
      _floatingOpacity = 1;
      _floatingOffset = 0;
    });

    const steps = 20;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() {
        _floatingOffset = -(40 * i / steps);
        _floatingOpacity = 1 - (i / steps);
      });
    }
    if (!mounted) return;
    setState(() => _showFloating = false);

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    widget.onClaimed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard(context),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary(context), size: 13),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent(context).withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _claimed ? '100 ⭐️' : '10 ⭐️',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent(context),
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_showFloating)
                    Positioned(
                      top: _floatingOffset,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Opacity(
                          opacity: _floatingOpacity.clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+90 XP',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.accentText(context),
                                fontSize: 6,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.accent(context).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent(context).withValues(alpha: 0.4), width: 1),
            ),
            child: const Center(child: Text('⭐️', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 14),
          Text('Session Complete!',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('You earned +90 ⭐️',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context), fontSize: 10)),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _onClaimTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _claimed ? AppColors.success(context) : AppColors.accent(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent(context).withValues(alpha: _claimed ? 0.0 : 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _claimed ? '✓ Claimed!' : 'Claim Stars ⭐️',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accentText(context), fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          BouncingArrowUp(color: AppColors.textPrimary(context)), // 👈 explicit, matches surrounding text color          const SizedBox(height: 4),
          Text(
            'Tap to claim!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialShell extends StatelessWidget {
  final Widget child;
  const _TutorialShell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent(context).withValues(alpha: 0.04),
                border: Border.all(color: AppColors.accent(context).withValues(alpha: 0.07), width: 0.5),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(child: child),
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

class _TutorialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TutorialButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.accentText(context),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }
}