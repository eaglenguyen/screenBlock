// lib/onboarding_new/onboarding_flow.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/onboarding_new/screens/reassurance_screen.dart';
import 'package:pausenow/onboarding_new/screens/welcome_screen.dart';
import 'package:pausenow/onboarding_new/widget/demo_app_picker.dart';
import 'package:pausenow/onboarding_new/widget/demo_video.dart';
import 'package:uuid/uuid.dart';
import '../UI/appPicker/app_picker_viewmodel.dart';
import '../UI/schedule/schedule_viewmodel.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/hivebox_names.dart';
import '../onboarding/onboarding_demo_screens.dart';
import '../onboarding/onboarding_viewmodel.dart';
import 'data/onboarding_data.dart';
import 'gauntlet/schedule_gauntlet_state.dart';
import 'gauntlet/screens/day_pick.dart';
import 'gauntlet/screens/equip_screen.dart';
import 'gauntlet/screens/intro_screen.dart';
import 'gauntlet/screens/screen_time.dart';
import 'gauntlet/screens/time_range.dart';
import 'onboarding_step_id.dart';
import 'widget/single_choice_screen.dart';
import 'screens/name_screen.dart';

class OnboardingFlow extends ConsumerStatefulWidget { // 👈 was StatefulWidget
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState(); // 👈 was State<OnboardingFlow>
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late OnboardingStepId _currentStep;
  final _data = OnboardingData();
  bool _isNavigating = false; // 👈 new
  final _gauntlet = ScheduleGauntletState();
  final String _gauntletScheduleId = const Uuid().v4();

  Future<void> _saveGauntletSchedule() async {
    final start = _gauntlet.startTime;
    final end = _gauntlet.endTime;
    if (start == null || end == null) return; // shouldn't happen given the flow order, but guards against bad state

    String fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    try {
      await ref.read(scheduleViewModelProvider.notifier).saveSchedule(
        existingId: _gauntletScheduleId, // 👈 the same id used when the app picker wrote its selection
        name: _gauntlet.name ?? 'Focus Time',
        startTime: fmt(start),
        endTime: fmt(end),
        days: _gauntlet.days,
        blockingType: AppConstants.blockingTypeSpecificApps,
        blockedApps: _gauntlet.apps,
        allowedApps: const [],
      );
    } catch (e) {
      debugPrint('❌ gauntlet schedule save error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _currentStep = OnboardingFlowController.order.first;
    ref.read(appPickerViewModelProvider.notifier).loadApps(); // 👈 new — fire-and-forget, way ahead of when it's needed
  }

  void _goNext() {
    if (_isNavigating) return; // 👈 new
    _isNavigating = true;

    final next = OnboardingFlowController.next(_currentStep);
    if (next == null) {
      _onOnboardingComplete();
      _isNavigating = false; // 👈 new — no further screen transition happens, so unlock immediately
      return;
    }
    setState(() => _currentStep = next);

    Future.delayed(const Duration(milliseconds: 500), () { // 👈 new — unlocks after the screen transition settles
      if (mounted) _isNavigating = false;
    });
  }

  void _goBack() {
    if (_isNavigating) return; // 👈 new
    _isNavigating = true;

    final prev = OnboardingFlowController.previous(_currentStep);
    if (prev == null) {
      _isNavigating = false; // 👈 new
      return;
    }
    setState(() => _currentStep = prev);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _isNavigating = false;
    });
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
      case OnboardingStepId.gauntletIntro:
        return OnboardingGauntletIntroScreen(
          key: const ValueKey('gauntletIntro'),
          progressStep: OnboardingFlowController.order.indexOf(OnboardingStepId.gauntletIntro) + 1,
          progressTotal: OnboardingFlowController.order.length,
          onBack: _goBack,
          onContinue: _goNext,
        );
      case OnboardingStepId.screenTimeGuess:
        return OnboardingScreenTimeGuessScreen(
          key: const ValueKey('screenTimeGuess'),
          progressStep: OnboardingFlowController.order.indexOf(OnboardingStepId.screenTimeGuess) + 1,
          progressTotal: OnboardingFlowController.order.length,
          onBack: _goBack,
          onContinue: (hours) {
            _data.screenTimeGuess = hours;
            _goNext();
          },
        );
      case OnboardingStepId.gauntletAppsPicker:
        return DemoAppPickerScreen(
          key: const ValueKey('gauntletAppsPicker'),
          scheduleId: _gauntletScheduleId,
          progressStep: OnboardingFlowController.order.indexOf(OnboardingStepId.gauntletAppsPicker) + 1, // 👈 was: progress: (...) / OnboardingFlowController.order.length,
          progressTotal: OnboardingFlowController.order.length, // 👈 new
          onBack: _goBack,
          onAppsSelected: (apps) {
            _gauntlet.apps = apps;
            _goNext();
          },
        );
      case OnboardingStepId.gauntletEquip1:
        return OnboardingGauntletEquipScreen(
          key: const ValueKey('gauntletEquip1'),
          state: _gauntlet,
          justFilled: ScheduleStone.apps,
          stepNumber: 1,
          onContinue: _goNext,
        );
      case OnboardingStepId.gauntletTimeRange:
        return OnboardingGauntletTimeRangeScreen(
          key: const ValueKey('gauntletTimeRange'),
          progressStep: OnboardingFlowController.order.indexOf(OnboardingStepId.gauntletTimeRange) + 1,
          progressTotal: OnboardingFlowController.order.length,
          onBack: _goBack,
          onContinue: (start, end) {
            _gauntlet.startTime = start;
            _gauntlet.endTime = end;
            _goNext();
          },
        );
      case OnboardingStepId.gauntletEquip2:
        return OnboardingGauntletEquipScreen(
          key: const ValueKey('gauntletEquip2'),
          state: _gauntlet,
          justFilled: ScheduleStone.time,
          stepNumber: 2,
          onContinue: _goNext,
        );
      case OnboardingStepId.gauntletDays:
        return OnboardingGauntletDaysScreen(
          key: const ValueKey('gauntletDays'),
          progressStep: OnboardingFlowController.order.indexOf(OnboardingStepId.gauntletDays) + 1,
          progressTotal: OnboardingFlowController.order.length,
          onBack: _goBack,
          onContinue: (days) {
            _gauntlet.days = days;
            _goNext();
          },
        );
      case OnboardingStepId.gauntletEquip3:
        return OnboardingGauntletEquipScreen(
          key: const ValueKey('gauntletEquip3'),
          state: _gauntlet,
          justFilled: ScheduleStone.days,
          stepNumber: 3,
          onContinue: _goNext,
        );
      case OnboardingStepId.gauntletName:
        return OnboardingNameScreen(
          key: const ValueKey('gauntletName'),
          progressStep: OnboardingFlowController.order.indexOf(OnboardingStepId.gauntletName) + 1,
          progressTotal: OnboardingFlowController.order.length,
          title: 'Name your schedule!',
          subtitle: "Give it a name you'll recognize later.",
          hint: 'e.g. Focus Time',
          continueLabel: 'Continue',
          showRandomizer: true, // 👈 new
          onBack: _goBack,
          onContinue: (name) async { // 👈 now async
            _gauntlet.name = name;
            await _saveGauntletSchedule(); // 👈 new — actually creates the schedule
            _goNext();
          },
        );
      case OnboardingStepId.gauntletEquip4:
        return OnboardingGauntletEquipScreen(
          key: const ValueKey('gauntletEquip4'),
          state: _gauntlet,
          justFilled: ScheduleStone.name,
          stepNumber: 4,
          showConfetti: true,
          onContinue: _goNext,
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


