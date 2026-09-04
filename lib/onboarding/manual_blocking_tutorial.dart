import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pausenow/onboarding/widgets/bouncing_arrow.dart';

// ── Manual Blocking Tutorial Flow ────────────────────
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

// ── Step 4 — Home screen overview ────────────────────
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
            'The longer your block session,\nthe more ⭐️ you gain!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
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

// ── Step 1 — Block Mode sheet ─────────────────────────
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
          const Expanded(child: SizedBox()), // 👈 was SizedBox(height: 130) — now flexible, centers content vertically
          const _StepLabel(step: 1),
          const SizedBox(height: 8),
          Text(
            'Choose your block mode',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
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
                border: Border.all(color: const Color(0xFF3A3A5C), width: 2.5),
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
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step 2 — App picker ───────────────────────────────
class _ManualStep3AppPicker extends StatelessWidget {
  final VoidCallback onNext;
  const _ManualStep3AppPicker({super.key, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return _TutorialShell(
      child: Column(
        children: [
          const Expanded(child: SizedBox()), // 👈 was SizedBox(height: 130) — now flexible, centers content vertically
          const _StepLabel(step: 2),
          const SizedBox(height: 8),
          Text(
            'Choose the apps that you want blocked',
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
            'The most distracting apps are recommended',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
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

// ── Step 3 — Set timer ────────────────────────────────
class _ManualStep4Timer extends StatelessWidget {
  final VoidCallback onNext;
  const _ManualStep4Timer({super.key, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return _TutorialShell(
      child: Column(
        children: [
          const Expanded(child: SizedBox()), // 👈 was SizedBox(height: 130) — now flexible, centers content vertically
          const _StepLabel(step: 3),
          const SizedBox(height: 8),
          Text(
            'Set your focus time',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
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

// ── Step 5 — Claim Stars ──────────────────────────────
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
            'Once your session ends, tap Claim\nto collect the stars you earned!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
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
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared step label ─────────────────────────────────
class _StepLabel extends StatelessWidget {
  final int step;
  const _StepLabel({required this.step});
  @override
  Widget build(BuildContext context) {
    return Text(
      '$step.',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ── Phone mockup wrapper ──────────────────────────────
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
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF3A3A5C), width: 2.5),
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

// ── Mockup — Home screen (with scattered blocked-app screenshot) ──
class _HomeScreenMockup extends StatelessWidget {
  const _HomeScreenMockup();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
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
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: Colors.white38, size: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '10 ⭐️',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEDB82A),
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
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF333333), width: 0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time Blocked Today',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['00', '00', '00'].expand((t) sync* {
                    yield Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(t,
                          style: GoogleFonts.poppins(
                              color: Colors.white54,
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
                          color: const Color(0xFF2E2E2E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('🛡️ Specific Apps',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 6),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2E2E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('⏱ 3h',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 6)),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDB82A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '▶  Start',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1A1208),
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
          // 👇 new — the blocked-apps screenshot, dropped straight in
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/appsLocked.png', // 👈 save your screenshot here
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}



// ── Mockup — Block Mode sheet ─────────────────────────
class _BlockModeSheetMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18), // 👈 was (12, 10, 12, 12)
      decoration: const BoxDecoration(
        color: Color(0xFF252525),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, // 👈 was 28, 3
              decoration: BoxDecoration(color: const Color(0xFF444444), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12), // 👈 was 8
          Text('Block Mode', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)), // 👈 was 11
          const SizedBox(height: 12), // 👈 was 8
          Container(
            padding: const EdgeInsets.all(4), // 👈 was 3
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8), // 👈 was 5
                    decoration: BoxDecoration(color: const Color(0xFF2E2E2E), borderRadius: BorderRadius.circular(20)),
                    child: Text('All Apps', textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)), // 👈 was 7
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8), // 👈 was 5
                    decoration: BoxDecoration(color: const Color(0xFFEDB82A), borderRadius: BorderRadius.circular(20)),
                    child: Text('Specific Apps', textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: const Color(0xFF1A1208), fontSize: 10, fontWeight: FontWeight.w700)), // 👈 was 7
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12), // 👈 was 8
          Container(
            padding: const EdgeInsets.all(12), // 👈 was 8
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Blocked Apps', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)), // 👈 was 8
                    Text('Only these apps will be blocked', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9)), // 👈 was 6
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16), // 👈 was 12
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ── Mockup — App picker ───────────────────────────────
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
    final apps = [
      _AppItem(name: 'Instagram', selected: true,
          icon: 'assets/icons/instagram.svg', color: const Color(0xFFE1306C)),
      _AppItem(name: 'TikTok', selected: true,
          icon: 'assets/icons/tiktok.svg', color: Colors.white),
      _AppItem(name: 'YouTube', selected: false,
          icon: 'assets/icons/youtube.svg', color: const Color(0xFFFF0000)),
      _AppItem(name: 'Twitter', selected: false,
          icon: 'assets/icons/twitter-x.svg', color: const Color(0xFF1DA1F2)),
    ];
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 8)),
              Text('Select Apps',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              Text('Save',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFEDB82A), fontSize: 8, fontWeight: FontWeight.w700)),
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
                    color: app.selected ? const Color(0xFFEDB82A) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: app.selected ? const Color(0xFFEDB82A) : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: app.selected
                      ? const Icon(Icons.check_rounded, color: Color(0xFF1A1208), size: 8)
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
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          )),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.white38, size: 10),
                const SizedBox(width: 4),
                Text('Search', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 7)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mockup — Timer sheet (updated to ruler-picker style) ──
class _TimerSheetMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF252525),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                          color: const Color(0xFF444444),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Text('Set Timer',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  // big duration readout
                  Text(
                    '3h',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFEDB82A),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // flanking labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1h',
                          style: GoogleFonts.poppins(
                              color: Colors.white24, fontSize: 9)),
                      Text('5h',
                          style: GoogleFonts.poppins(
                              color: Colors.white24, fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ruler ticks mockup
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
                              color: Colors.white.withValues(alpha: isMajor ? 0.35 : 0.15),
                            );
                          }),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          color: const Color(0xFF3B82F6),
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

// ── Mockup — Claim Stars (interaction + header badge moved here) ─────
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

    // 👇 badge floating animation, same treatment as the original home screen header
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
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Column(
        children: [
          // 👇 header row — moved from step 4, person icon + XP badge with floating label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 13),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _claimed ? '100 ⭐️' : '10 ⭐️',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFEDB82A),
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
                              color: const Color(0xFFEDB82A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+90 XP',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1A1208),
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
              color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEDB82A).withValues(alpha: 0.4), width: 1),
            ),
            child: const Center(child: Text('⭐️', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 14),
          Text('Session Complete!',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('You earned +90 ⭐️',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _onClaimTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _claimed ? const Color(0xFF4CAF50) : const Color(0xFFEDB82A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEDB82A).withValues(alpha: _claimed ? 0.0 : 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _claimed ? '✓ Claimed!' : 'Claim Stars ⭐️',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF1A1208), fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const BouncingArrowUp(),
          const SizedBox(height: 4),
          Text(
            'Tap to claim!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
// ── Shared shell ──────────────────────────────────────
class _TutorialShell extends StatelessWidget {
  final Widget child;
  const _TutorialShell({required this.child});
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
                colors: [Color(0xFF1a0a3d), Color(0xFF16162a), Color(0xFF0a1a2a)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEDB82A).withValues(alpha: 0.04),
                border: Border.all(color: const Color(0xFFEDB82A).withValues(alpha: 0.07), width: 0.5),
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

// ── Shared button ─────────────────────────────────────
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
          backgroundColor: const Color(0xFFEDB82A),
          foregroundColor: const Color(0xFF1A1208),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
        child: Text(label),
      ),
    );
  }
}
