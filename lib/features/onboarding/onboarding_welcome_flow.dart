import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../../core/constants/hivebox_names.dart';
import '../paywall/onboarding_outlook_screen.dart';
import 'data/onboarding_stats.dart';
import 'onboarding_permission_screen.dart';
import 'onboarding_question_bank.dart';
import 'widgets/onboarding_animations.dart';
import 'onboarding_chat_screen.dart';
import 'onboarding_demo_screens.dart';
import 'onboarding_personal_flow.dart';
import 'onboarding_viewmodel.dart';


class OnboardingSteps {
  static const int welcome = 0;
  static const int chatIntro = 1;
  static const int chat = 2;
  static const int ageQuestion = 3;
  static const int hoursQuestion = 4;
  static const int badNewsStats = 5;
  static const int lifeGrid = 6;
  static const int goodNews = 7;
  static const int qbGoals = 8;
  static const int qbFutureVision = 9;
  static const int qbGoalsConfirm = 10;
  static const int qbPhoneUsage = 11;
  static const int qbSocialMedia = 12;
  static const int qbBlockers = 13;
  static const int qbStruggles = 14;
  static const int qbSympathy = 15;
  static const int permissions = 16;
  static const int demo = 17;
  static const int commitment = 18;
  static const int commitmentResult = 19;
  static const int reviewPopup = 20;
  static const int themePicker = 21;
  static const int screenTimeGoal = 22;
  static const int loadingPlan = 23;
  static const int reflection = 24;
  static const int outlook = 25;
  static const int trialReminder = 26;
  static const int paywall = 27;
}

class OnboardingWelcomeFlow extends ConsumerStatefulWidget {
  const OnboardingWelcomeFlow({super.key});

  @override
  ConsumerState<OnboardingWelcomeFlow> createState() =>
      _OnboardingWelcomeFlowState();
}

class _OnboardingWelcomeFlowState
    extends ConsumerState<OnboardingWelcomeFlow> {

  String get _userName => ref.read(onboardingViewModelProvider).userName ?? '';
  int _currentStep = OnboardingSteps.welcome;
  // add to _OnboardingWelcomeFlowState
  int _userAge = 21;
  double _userHours = 3.5;
  List<String> _selectedGoals = [];
  String _selectedFuture = '';
  String _commitmentLevel = '';
  bool _isHighCommitment = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  OnboardingStatsData get _statsData => OnboardingStatsData(
    age: _userAge,
    hoursPerDay: _userHours,
  );


  void _nextStep() {
    HapticFeedback.lightImpact();
    final nextStep = _currentStep + 1;
    setState(() => _currentStep = nextStep);
    _saveProgress(nextStep);
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep--);
  }

  void _saveProgress(int step) {
    final box = Hive.box(HiveBoxNames.settings);
    box.put('onboardingStep', step);
    box.put('onboardingAge', _userAge);
    box.put('onboardingHours', _userHours);
    box.put('onboardingGoals', _selectedGoals);
    box.put('onboardingFuture', _selectedFuture);
    box.put('onboardingCommitment', _commitmentLevel);
    box.put('onboardingHighCommitment', _isHighCommitment);
  }

  void _loadProgress() {
    final box = Hive.box(HiveBoxNames.settings);
    int savedStep = box.get('onboardingStep', defaultValue: 0) as int;

    const autoAdvanceSteps = [
      OnboardingSteps.reviewPopup,
      OnboardingSteps.paywall,
    ];
    if (autoAdvanceSteps.contains(savedStep)) {
      savedStep = savedStep - 1;
    }

    // 👇 set directly, no setState — widget isn't mounted yet
    _currentStep = savedStep;
    _userAge = box.get('onboardingAge', defaultValue: 21) as int;
    _userHours = box.get('onboardingHours', defaultValue: 3.5) as double;
    _selectedGoals = List<String>.from(
        box.get('onboardingGoals', defaultValue: <String>[]));
    _selectedFuture = box.get('onboardingFuture', defaultValue: '') as String;
    _commitmentLevel = box.get('onboardingCommitment', defaultValue: '') as String;
    _isHighCommitment = box.get('onboardingHighCommitment', defaultValue: false) as bool;
  }



  Future<void> _onComplete() async {
    final box = Hive.box(HiveBoxNames.settings);
    await box.put('onboardingComplete', true);
    await box.delete('onboardingStep'); // 👈 clean up saved step
    await ref
        .read(onboardingViewModelProvider.notifier)
        .completeOnboarding();
    if (mounted) context.go('/paywall');
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
          onSkip: _onComplete,
        );
      case OnboardingSteps.chatIntro:
        return OnboardingChatIntroScreen(
          key: const ValueKey('chatIntro'),
          onStart: _nextStep,
        );
      case OnboardingSteps.chat:
        return KeyedSubtree(
          key: const ValueKey('chat'),
          child: OnboardingChatScreen(
            onChatComplete: _nextStep,
          ),
        );
      case OnboardingSteps.ageQuestion:
        return OnboardingAgeScreen(
          key: const ValueKey('age'),
          onBack: _previousStep,
          onSelected: (age) {
            _userAge = age;
            _nextStep();
          },
        );
      case OnboardingSteps.hoursQuestion:
        return OnboardingHoursScreen(
          key: const ValueKey('hours'),
          onBack: _previousStep,
          onSelected: (hours) {
            _userHours = hours;
            _nextStep();
          },
        );
      case OnboardingSteps.badNewsStats:
        return OnboardingBadNewsScreen(
          key: const ValueKey('badnews'),
          onBack: _previousStep,
          onNext: _nextStep,
          data: _statsData,
          userName: _userName,
        );
      case OnboardingSteps.lifeGrid:
        return OnboardingLifeGridScreen(
          key: const ValueKey('lifegrid'),
          onBack: _previousStep,
          onNext: _nextStep,
          data: _statsData,
        );
      case OnboardingSteps.goodNews:
        return OnboardingGoodNewsScreen(
          key: const ValueKey('goodnews'),
          onBack: _previousStep,
          onNext: _nextStep,
          data: _statsData,
          userName: _userName,

        );
      case OnboardingSteps.qbGoals:
        return QBGoalsScreen(
          key: const ValueKey('qbGoals'),
          onNext: (goals) {
            setState(() => _selectedGoals = goals);
            _nextStep();
          },
        );
      case OnboardingSteps.qbFutureVision:
        return QBFutureVisionScreen(
          key: const ValueKey('qbFuture'),
          onNext: (answer) {
            setState(() => _selectedFuture = answer);
            _nextStep();
          },
        );
      case OnboardingSteps.qbGoalsConfirm:
        return OnboardingGoalsConfirmScreen(
          key: const ValueKey('qbGoalsConfirm'),
          selectedGoals: _selectedGoals,
          futureVision: _selectedFuture,
          onNext: _nextStep,
        );
      case OnboardingSteps.qbPhoneUsage:
        return QBPhoneUsageScreen(
          key: const ValueKey('qbPhone'),
          onNext: (_) => _nextStep(),
        );
      case OnboardingSteps.qbSocialMedia:
        return QBSocialMediaRelationshipScreen(
          key: const ValueKey('qbSocial'),
          onNext: (_) => _nextStep(),
        );
      case OnboardingSteps.qbBlockers:
        return QBBlockersScreen(
          key: const ValueKey('qbBlockers'),
          onNext: (_) => _nextStep(),
        );
      case OnboardingSteps.qbStruggles:
        return QBStrugglesScreen(
          key: const ValueKey('qbStruggles'),
          onNext: (_) => _nextStep(),
        );
      case OnboardingSteps.qbSympathy: // 👈 new
        return QBSympathyScreen(
          key: const ValueKey('qbSympathy'),
          userName: _userName,
          onNext: _nextStep,
        );

      case OnboardingSteps.permissions:
        return OnboardingPermissionsScreen(
          key: const ValueKey('permissions'),
          onNext: _nextStep,
        );
      case OnboardingSteps.demo:
        return KeyedSubtree(
          key: const ValueKey('demo'),
          child: OnboardingDemoFlow(
            onComplete: _nextStep,
          ),
        );
      case OnboardingSteps.commitment:
        return QBCommitmentScreen(
          key: const ValueKey('commitment'),
          onNext: (level, isHigh) {
            setState(() {
              _commitmentLevel = level;
              _isHighCommitment = isHigh;
            });
            _nextStep();
          },
        );
      case OnboardingSteps.commitmentResult:
        return _isHighCommitment
            ? QBCommitmentHighScreen(
          key: const ValueKey('commitHigh'),
          level: _commitmentLevel,
          onNext: _nextStep,
        )
            : QBCommitmentLowScreen(
          key: const ValueKey('commitLow'),
          level: _commitmentLevel,
          onNext: _nextStep,
        );
      case OnboardingSteps.reviewPopup:
        WidgetsBinding.instance.addPostFrameCallback((_) => _nextStep());
        return const SizedBox.shrink();
      case OnboardingSteps.themePicker:
        return OnboardingThemeScreen(
          key: const ValueKey('theme'),
          onNext: _nextStep,
        );
      case OnboardingSteps.screenTimeGoal:
        return OnboardingScreenTimeGoalScreen(
          key: const ValueKey('screenTimeGoal'),
          onSelected: (hours) {
            final box = Hive.box(HiveBoxNames.settings);
            box.put('dailyScreenTimeGoal', hours.toDouble());
            _nextStep();
          },
        );
      case OnboardingSteps.loadingPlan:
        return OnboardingLoadingPlanScreen(
          key: const ValueKey('loadingPlan'),
          onComplete: _nextStep,
        );
      case OnboardingSteps.reflection:
        return OnboardingProductivityScreen(
          key: const ValueKey('productivity'),
          onBack: _previousStep,
          onNext: _nextStep,
        );
      case OnboardingSteps.outlook:
        return OnboardingOutlookScreen(
          key: const ValueKey('outlook'),
          onNext: _nextStep,
        );
      case OnboardingSteps.trialReminder:
        return OnboardingTrialReminderScreen(
          key: const ValueKey('trialReminder'),
          onNext: _nextStep,
        );
      case OnboardingSteps.paywall:
        WidgetsBinding.instance.addPostFrameCallback((_) => _onComplete());
        return const SizedBox.shrink();
      default:
        WidgetsBinding.instance.addPostFrameCallback((_) => _onComplete());
        return const SizedBox.shrink();
    }
  }
}

// ── Screen 1 — Welcome ────────────────────────────────

class _WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  const _WelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onSkip,
  });

  @override
  State<_WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<_WelcomeScreen> {
  int _slide = 0;

  void _advance() {
    if (_slide < 2) {
      setState(() => _slide++);
    } else {
      widget.onGetStarted();
    }
  }

  Widget _buildStatement() {
    switch (_slide) {
      case 0:
        return RichText(
          key: const ValueKey(0),
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            children: const [
              TextSpan(
                text: '66 days.',
                style: TextStyle(color: Color(0xFFEDB82A)),
              ),
              TextSpan(
                text: " That's how long it takes to build a new habit.",
              ),
            ],
          ),
        );
      case 1:
        return Text(
          'The secret? Pausing and being present in the moment.',
          key: const ValueKey(1),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        );
      case 2:
        return Text(
          'Pause Now turns that discipline into a lifestyle. Starting today.',
          key: const ValueKey(2),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _slide == 2;

    return GestureDetector(
      onTap: _advance,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E1A),
        body: Stack(
          children: [
            // subtle gradient bg
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0E0E1A),
                    Color(0xFF0A1628),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // debug skip button — remove before release
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: widget.onSkip,
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
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // app name
                    Text(
                      'pause now',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFEDB82A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // progress dots
                    Row(
                      children: List.generate(3, (i) {
                        final isActive = i <= _slide;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: isActive ? 28 : 20,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFEDB82A)
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // bold statement
                    // bold statement
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      transitionBuilder: (child, animation) {
                        final isEntering = animation.status == AnimationStatus.forward ||
                            animation.status == AnimationStatus.completed;

                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: isEntering
                                ? const Offset(-1, 0)   // 👈 entering slides in from right
                                : const Offset(1, 0), // 👈 exiting slides out to left
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: _buildStatement(),
                    ),

                    const Spacer(flex: 3),

                    // bottom CTA
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isLast
                          ? SizedBox(
                        key: const ValueKey('btn'),
                        width: double.infinity,
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: widget.onGetStarted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFFEDB82A),
                                foregroundColor:
                                const Color(0xFF1A1208),
                                minimumSize:
                                const Size(double.infinity, 58),
                                shape: const StadiumBorder(),
                                elevation: 0,
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: const Text('Get Started →'),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Free 7-day trial · No signup required',
                              style: GoogleFonts.poppins(
                                color: Colors.white
                                    .withValues(alpha: 0.28),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                          : Padding(
                        key: const ValueKey('tap'),
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Center(
                          child: Text(
                            'Tap to continue',
                            style: GoogleFonts.poppins(
                              color: Colors.white
                                  .withValues(alpha: 0.3),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Screen 2 — Username ───────────────────────────────

class _UsernameScreen extends StatefulWidget {
  final Function(String name) onContinue;
  final VoidCallback onBack;
  const _UsernameScreen({
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