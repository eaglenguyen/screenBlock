import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_animations.dart';
import 'onboarding_chat_screen.dart';
import 'onboarding_demo_screens.dart';
import 'onboarding_viewmodel.dart';



class OnboardingSteps {
  static const int welcome = 0;
  static const int username = 1;
  static const int referral = 2;
  static const int chat = 3;
  static const int demo = 4;
}

class OnboardingWelcomeFlow extends ConsumerStatefulWidget {
  const OnboardingWelcomeFlow({super.key});

  @override
  ConsumerState<OnboardingWelcomeFlow> createState() =>
      _OnboardingWelcomeFlowState();
}

class _OnboardingWelcomeFlowState
    extends ConsumerState<OnboardingWelcomeFlow> {

  int _currentStep = OnboardingSteps.welcome;
  String _userName = '';
  String _referral = '';

  void _nextStep() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep++);
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep--);
  }

  void _onUsernameSubmitted(String name) {
    if (name.trim().isEmpty) return;
    _userName = name.trim();
    _nextStep();
  }

  void _onReferralSelected(String source) {
    _referral = source;
    _nextStep();
  }

  Future<void> _onComplete() async {
    await ref
        .read(onboardingViewModelProvider.notifier)
        .completeOnboarding();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
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
    switch (_currentStep) {
      case OnboardingSteps.welcome:
        return _WelcomeScreen(
          key: const ValueKey('welcome'),
            onGetStarted: _nextStep,
            //remove debug
            onSkip: _onComplete
        );
      case OnboardingSteps.username:
        return _UsernameScreen(
          key: const ValueKey('username'),
          onContinue: _onUsernameSubmitted,
          onBack: _previousStep,
        );
      case OnboardingSteps.referral:
        return _ReferralScreen(
          key: const ValueKey('referral'),
          onSelected: _onReferralSelected,
          onBack: _previousStep,
        );
      case OnboardingSteps.chat:
        return KeyedSubtree(
          key: const ValueKey('chat'),
          child: OnboardingChatScreen(
            onChatComplete: _nextStep,
          ),
        );
      case OnboardingSteps.demo:
        return KeyedSubtree(
          key: const ValueKey('demo'),
          child: OnboardingDemoFlow(
            onComplete: _nextStep,
          ),
        );
      default:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onComplete();
        });
        return const SizedBox.shrink();
    }
  }
}

// ── Screen 1 — Welcome ────────────────────────────────

class _WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  // Debug button, remove this
  final VoidCallback onSkip;
  const _WelcomeScreen({super.key, required this.onGetStarted, required this.onSkip});

  @override
  State<_WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<_WelcomeScreen>
    with SingleTickerProviderStateMixin, OnboardingEntranceMixin {

  @override
  void initState() {
    super.initState();
    initEntrance(elementCount: 4);
  }

  @override
  void dispose() {
    disposeEntrance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          _buildGradientBg(),
          _buildCircles(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: Column(
                children: [
                  // Remove when production happens
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: widget.onSkip, // 👈 skips straight to next step
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Skip (debug)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // element 0 — logo
                  staggered(
                    0,
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDB82A)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFEDB82A)
                              .withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text('🛡️',
                            style: TextStyle(fontSize: 42)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // element 1 — title with gold word
                  staggered(
                    1,
                    const GoldText(
                      text: 'Screen\nBlock',
                      goldWord: 'Block',
                      fontSize: 44,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // element 2 — subtitle
                  staggered(
                    2,
                    Text(
                      'Break free from endless scrolling\nand reclaim your time',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 17,
                        height: 1.55,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // element 3 — button + note
                  staggered(
                    3,
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        ShimmerButton(
                          label: 'Get Started →',
                          onTap: widget.onGetStarted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Free 3-day trial · No credit card required',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28),
                            fontSize: 13,
                          ),
                        ),
                      ],
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

// ── Screen 2 — Username ───────────────────────────────

class _UsernameScreen extends StatefulWidget {
  final Function(String name) onContinue;
  final VoidCallback onBack;
  const _UsernameScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<_UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<_UsernameScreen>
    with SingleTickerProviderStateMixin, OnboardingEntranceMixin {

  final TextEditingController _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    initEntrance(elementCount: 4);
    _ctrl.addListener(() {
      setState(() => _hasText = _ctrl.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    disposeEntrance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          _buildGradientBg(),
          _buildCircles(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
              child: Column(
                children: [
                  // element 0 — back + progress
                  staggered(
                    0,
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onBack,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProgressBar(step: 1, total: 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // element 1 — headline with gold word
                  staggered(
                    1,
                    const GoldText(
                      text: 'Choose a username',
                      goldWord: 'username',
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // element 2 — subtitle + text field
                  staggered(
                    2,
                    Column(
                      children: [
                        Text(
                          'This is how we\'ll address you\nthroughout the app',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 44),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252542),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _hasText
                                  ? const Color(0xFFEDB82A)
                                  .withValues(alpha: 0.5)
                                  : const Color(0xFF2A2A48),
                              width: _hasText ? 1.5 : 0.5,
                            ),
                            boxShadow: _hasText
                                ? [
                              BoxShadow(
                                color: const Color(0xFFEDB82A)
                                    .withValues(alpha: 0.12),
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
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'your name...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.2),
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                            ),
                            onSubmitted: (_) {
                              if (_hasText) widget.onContinue(_ctrl.text);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // element 3 — button
                  staggered(
                    3,
                    AnimatedOpacity(
                      opacity: _hasText ? 1.0 : 0.35,
                      duration: const Duration(milliseconds: 200),
                      child: ShimmerButton(
                        label: 'Continue →',
                        onTap: _hasText
                            ? () => widget.onContinue(_ctrl.text)
                            : () {},
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

// ── Screen 3 — Referral ───────────────────────────────

class _ReferralScreen extends StatefulWidget {
  final Function(String source) onSelected;
  final VoidCallback onBack;

  const _ReferralScreen({
    super.key,
    required this.onSelected,
    required this.onBack,
  });

  @override
  State<_ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<_ReferralScreen>
    with SingleTickerProviderStateMixin, OnboardingEntranceMixin {
  String? _selected;

  final List<Map<String, dynamic>> _options = [
    {
      'icon': 'assets/icons/youtube.svg',
      'bgColor': const Color(0xFFFF0000),
      'label': 'YouTube',
    },
    {
      'icon': 'assets/icons/instagram.svg',
      'bgColor': const Color(0xFFE1306C),
      'label': 'Instagram',
    },
    {
      'icon': 'assets/icons/tiktok.svg',
      'bgColor': Colors.white,
      'label': 'TikTok',
    },
    {
      'icon': 'assets/icons/appstore.svg',
      'bgColor': const Color(0xFF0D96F6),
      'label': 'App Store',
    },
    {
      'icon': null,
      'bgColor': const Color(0xFF7070A0),
      'label': 'Other',
      'emoji': '✨',
    },
  ];
  @override
  void initState() {
    super.initState();
    initEntrance(elementCount: 3);
  }

  @override
  void dispose() {
    disposeEntrance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          _buildGradientBg(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // element 0 — back + progress
                  staggered(
                    0,
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onBack,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProgressBar(step: 2, total: 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),

                  // element 1 — headline with gold word
                  staggered(
                    1,
                    const GoldText(
                      text: 'Where did you\nhear about us?',
                      goldWord: 'hear',
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // element 2 — options list
                  Expanded(
                      child: staggered(
                        2,
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _options.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final opt = _options[i];
                            final isSelected = _selected == opt['label'];
                            return AnimatedOptionCard(
                              isSelected: isSelected,
                              onTap: () {
                                setState(() => _selected = opt['label'] as String);
                              },
                            child: Row(
                              children: [
                                // icon container
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: (opt['bgColor'] as Color)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: (opt['bgColor'] as Color)
                                          .withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: opt['icon'] != null
                                        ? Text('') // replace with SvgPicture.asset
                                        : Text(
                                      opt['emoji'] as String,
                                      style: const TextStyle(
                                          fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  opt['label'] as String,
                                  style: TextStyle(
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
                                AnimatedCheckmark(visible: isSelected),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  AnimatedOpacity(
                    opacity: _selected != null ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 200),
                    child: ShimmerButton(
                      label: 'Continue →',
                      onTap: _selected != null
                          ? () => widget.onSelected(_selected!)
                          : () {},
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

// ── Shared helpers ────────────────────────────────────

Widget _buildGradientBg() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2A2015), // 👈 warm dark gold tint at top
          Color(0xFF1A1A1A), // 👈 charcoal mid
          Color(0xFF111111),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    ),
  );
}

Widget _buildCircles() {
  return Stack(
    children: [
      Positioned(
        top: -40,
        right: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEDB82A).withValues(alpha: 0.05),
            border: Border.all(
              color: const Color(0xFFEDB82A).withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -30,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4444AA).withValues(alpha: 0.05),
            border: Border.all(
              color: const Color(0xFF4444AA).withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildProgressBar({required int step, required int total}) {
  return Row(
    children: List.generate(total, (i) {
      final isActive = i < step;
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
          height: 3.5,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFEDB82A)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }),
  );
}