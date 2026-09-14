// lib/onboarding_new/onboarding_flow.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/onboarding_new/screens/reassurance_screen.dart';
import 'package:pausenow/onboarding_new/screens/welcome_screen.dart';
import 'package:pausenow/onboarding_new/widget/demo_video.dart';
import '../core/constants/hivebox_names.dart';
import '../onboarding/onboarding_viewmodel.dart';
import 'data/onboarding_data.dart';
import 'onboarding_step_id.dart';
import 'widget/single_choice_screen.dart';
import 'screens/name_screen.dart';

class OnboardingFlow extends ConsumerStatefulWidget { // 👈 was StatefulWidget
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState(); // 👈 was State<OnboardingFlow>
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> { // 👈 was State<OnboardingFlow>
  late OnboardingStepId _currentStep;
  final _data = OnboardingData();

  void _goBack() {
    final prev = OnboardingFlowController.previous(_currentStep);
    if (prev == null) return;
    setState(() => _currentStep = prev);
  }

  @override
  void initState() {
    super.initState();
    _currentStep = OnboardingFlowController.order.first;
  }

  void _goNext() {
    final next = OnboardingFlowController.next(_currentStep);
    if (next == null) {
      _onOnboardingComplete();
      return;
    }
    setState(() => _currentStep = next);
  }

  Future<void> _onOnboardingComplete() async {
    final box = Hive.box(HiveBoxNames.settings);
    await box.put('onboardingComplete', true);
    await box.delete('onboardingStepId');
    if (mounted) context.go('/paywall'); // 👈 same destination the old flow used
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
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case OnboardingStepId.welcome:
        return OnboardingWelcomeScreen(
          key: const ValueKey('welcome'),
          onGetStarted: _goNext,
        );
      case OnboardingStepId.need: // 👈 new
        return OnboardingSingleChoiceScreen(
          key: const ValueKey('need'),
          title: 'Whats your biggest need right now?',
          subtitle: "To give you the best start, we'd love to know what you most need help with in your daily life",
          options: const [
            'Stop Overthinking and Actually Starting',
            'Organize my Brain and Thoughts',
            'A Wheel of Tasks to Spin',
            'Block Apps and Stop Doomscrolling',
            'Help Deciding What I Need To Do',
          ],
          progressStep: 1,
          progressTotal: OnboardingFlowController.order.length,
          onBack: _goBack, // 👈 you'll need to add this method if it doesn't exist yet — see below
          onSelected: (choice) {
            _data.need = choice; // 👈 needs a matching field on OnboardingData
            _goNext();
          },
        );
      case OnboardingStepId.reassurance: // 👈 new
        return OnboardingReassuranceScreen(
          key: const ValueKey('reassurance'),
          onContinue: _goNext,
          onBack: _goBack, // 👈 new
          userNeed: _data.need,
        );
      case OnboardingStepId.neurodivergence:
        return OnboardingSingleChoiceScreen(
          key: const ValueKey('neurodivergence'),
          title: 'Are you\nneurodivergent?',
          subtitle: 'SpinBrek helps you stay focused and get things done with less friction. Which of these feels most like you?',
          options: const [
            'I am neurodivergent',
            'I think I am neurodivergent',
            'I am not neurodivergent',
          ],
          otherLabel: "I don't know",
          infoImageAsset: 'assets/images/neurodivergent.jpg', // 👈 new
          progressStep: 3,
          progressTotal: OnboardingFlowController.order.length,
          onBack: _goBack,
          onSelected: (choice) {
            _data.neurodivergenceStatus = choice;
            _goNext();
          },
        );
      case OnboardingStepId.name:
        return OnboardingNameScreen(
          key: const ValueKey('name'),
          progressStep: OnboardingFlowController.order.indexOf(OnboardingStepId.name) + 1,
          progressTotal: OnboardingFlowController.order.length,
          onBack: _goBack,
          onContinue: (name) {
            _data.name = name;
            // 👇 new — writes to the same two places SettingsProfileCard reads from
            ref.read(onboardingViewModelProvider.notifier).setUserName(name);
            Hive.box(HiveBoxNames.settings).put('userName', name);
            _goNext();
          },
        );
      case OnboardingStepId.age:
        return OnboardingSingleChoiceScreen(
          key: const ValueKey('age'),
          title: 'How old are you?',
          titleAlign: TextAlign.center,
          options: const ['Under 18', '18–24', '25–34', '35–44', '45–54', '55+'],
          optionIcons: const [
            Icons.child_care_rounded,
            Icons.school_rounded,
            Icons.work_outline_rounded,
            Icons.house,
            Icons.family_restroom_rounded,
            Icons.elderly_rounded,
          ],
          otherLabel: null, // 👈 no "something else" needed here
          progressStep: OnboardingFlowController.order.indexOf(OnboardingStepId.age) + 1,
          progressTotal: OnboardingFlowController.order.length,
          onBack: _goBack,
          onSelected: (choice) {
            _data.ageRange = choice;
            _goNext();
          },
        );
      case OnboardingStepId.demoVideo:
        return OnboardingDemoVideoScreen(
          key: const ValueKey('demoVideo'),
          progressStep: OnboardingFlowController.order.indexOf(OnboardingStepId.demoVideo) + 1,
          progressTotal: OnboardingFlowController.order.length,
          onBack: _goBack,
          onContinue: _goNext,
        );
    }
  }
}


