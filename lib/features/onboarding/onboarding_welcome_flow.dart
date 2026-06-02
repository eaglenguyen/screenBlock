import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingSteps {
  static const int welcome = 0;
  static const int username = 1;
  static const int referral = 2;
  static const int chat = 3;
}

class OnboardingWelcomeFlow extends ConsumerStatefulWidget {
  final Widget chatScreen;
  final VoidCallback? onComplete;

  const OnboardingWelcomeFlow({
    super.key,
    required this.chatScreen,
    this.onComplete,
  });

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

  void _onUsernameSubmitted(String name) {
    if (name.trim().isEmpty) return;
    _userName = name.trim();
    _nextStep();
  }

  void _onReferralSelected(String source) {
    _referral = source;
    _nextStep();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
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
        );
      case OnboardingSteps.username:
        return _UsernameScreen(
          key: const ValueKey('username'),
          onContinue: _onUsernameSubmitted,
        );
      case OnboardingSteps.referral:
        return _ReferralScreen(
          key: const ValueKey('referral'),
          onSelected: _onReferralSelected,
        );
      case OnboardingSteps.chat:
        return KeyedSubtree(
          key: const ValueKey('chat'),
          child: widget.chatScreen,
        );
      default:
        return widget.chatScreen;
    }
  }
}

// ── Screen 1 — Welcome ────────────────────────────────

class _WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  const _WelcomeScreen({super.key, required this.onGetStarted});

  @override
  State<_WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<_WelcomeScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
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
          _buildGradientBg(),
          _buildCircles(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        children: [
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
                          const SizedBox(height: 28),
                          const Text(
                            'ScreenBlock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Break free from endless scrolling\nand reclaim your time',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 17,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  SlideTransition(
                    position: _slide,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onGetStarted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEDB82A),
                                foregroundColor: const Color(0xFF1A1208),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20),
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              child: const Text('Get Started →'),
                            ),
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
  const _UsernameScreen({super.key, required this.onContinue});

  @override
  State<_UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<_UsernameScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _hasText = _ctrl.text.trim().isNotEmpty);
    });
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
          _buildGradientBg(),
          _buildCircles(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
              child: Column(
                children: [
                  _buildProgressBar(step: 1, total: 3),
                  const SizedBox(height: 60),

                  // centered headline
                  const Text(
                    'Choose a username',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
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

                  // text field
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252542),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _hasText
                            ? const Color(0xFFEDB82A).withValues(alpha: 0.5)
                            : const Color(0xFF2A2A48),
                        width: _hasText ? 1.5 : 0.5,
                      ),
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

                  const Spacer(),

                  AnimatedOpacity(
                    opacity: _hasText ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _hasText
                            ? () => widget.onContinue(_ctrl.text)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEDB82A),
                          foregroundColor: const Color(0xFF1A1208),
                          disabledBackgroundColor:
                          const Color(0xFFEDB82A).withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        child: const Text('Continue →'),
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
  const _ReferralScreen({super.key, required this.onSelected});

  @override
  State<_ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<_ReferralScreen> {
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
      'bgColor': const Color(0xFFEDB82A),
      'label': 'Friends',
      'emoji': '👥',
    },
    {
      'icon': null,
      'bgColor': const Color(0xFF7070A0),
      'label': 'Other',
      'emoji': '✨',
    },
  ];

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
                  _buildProgressBar(step: 2, total: 3),
                  const SizedBox(height: 44),

                  // centered headline
                  const Text(
                    'Where did you\nhear about us?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // full width vertical list
                  Expanded(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _options.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final opt = _options[i];
                        final isSelected = _selected == opt['label'];
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _selected = opt['label']);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
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
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: (opt['bgColor'] as Color).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: (opt['bgColor'] as Color).withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: opt['icon'] != null
                                        ? SvgPicture.asset(
                                      opt['icon'] as String,
                                      width: 20,
                                      height: 20,
                                      colorFilter: ColorFilter.mode(
                                        opt['bgColor'] as Color,
                                        BlendMode.srcIn,
                                      ),
                                    )
                                        : Text(
                                      opt['emoji'] as String,
                                      style: const TextStyle(fontSize: 18),
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
                                if (isSelected)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEDB82A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Color(0xFF1A1208),
                                      size: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  AnimatedOpacity(
                    opacity: _selected != null ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selected != null
                            ? () => widget.onSelected(_selected!)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEDB82A),
                          foregroundColor: const Color(0xFF1A1208),
                          disabledBackgroundColor:
                          const Color(0xFFEDB82A).withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        child: const Text('Continue →'),
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

// ── Shared helpers ────────────────────────────────────

Widget _buildGradientBg() {
  return Container(
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
      return Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
          height: 3.5,
          decoration: BoxDecoration(
            color: i < step
                ? const Color(0xFFEDB82A)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }),
  );
}