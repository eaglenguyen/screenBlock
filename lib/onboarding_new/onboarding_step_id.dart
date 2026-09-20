enum OnboardingStepId {
  welcome,
  need,
  reassurance,
  neurodivergence,
  name, // 👈 new
  age, // 👈 new
  screenTimeGuess, // 👈 new
  loadingProfile, // 👈 new
  badNews,
  goodNews,
  comparisonGraph,
  demoVideo,
  setupIntro,
  screenTimePermission,
  gauntletIntro, // 👈 new
  gauntletAppsPicker, // 👈 new
  gauntletEquip1, // 👈 new
  gauntletTimeRange, // 👈 new
  gauntletEquip2, // 👈 new
  gauntletDays, // 👈 new
  gauntletEquip3, // 👈 new
  hobbies,
  gauntletName, // 👈 new
  settingUp, // 👈 new
  gauntletEquip4, // 👈 new
  setMultipleSchedules,
  paywallIntro,
  commitmentSignature,
  demoComparison,
  trialReminder,
}

class OnboardingFlowController {
  OnboardingFlowController._();

  static const List<OnboardingStepId> order = [
    OnboardingStepId.welcome,

    OnboardingStepId.need,
    OnboardingStepId.reassurance,
    OnboardingStepId.neurodivergence,
    OnboardingStepId.name,
    OnboardingStepId.age,
    OnboardingStepId.screenTimeGuess,
    OnboardingStepId.loadingProfile, // 👈 new — right after screen time guess
    OnboardingStepId.badNews,
    OnboardingStepId.goodNews,
    OnboardingStepId.comparisonGraph,
    OnboardingStepId.demoVideo,
    OnboardingStepId.setupIntro,
    OnboardingStepId.screenTimePermission,
    OnboardingStepId.gauntletIntro, // 👈 new
    OnboardingStepId.gauntletAppsPicker,
    OnboardingStepId.gauntletEquip1,
    OnboardingStepId.gauntletTimeRange,
    OnboardingStepId.gauntletEquip2,
    OnboardingStepId.gauntletDays,
    OnboardingStepId.gauntletEquip3,
    OnboardingStepId.hobbies,
    OnboardingStepId.gauntletName,
    OnboardingStepId.settingUp, // 👈 new
    OnboardingStepId.gauntletEquip4,
    OnboardingStepId.setMultipleSchedules,
    OnboardingStepId.paywallIntro,
    OnboardingStepId.commitmentSignature,
    OnboardingStepId.demoComparison,
    OnboardingStepId.trialReminder,


  ];

  static int indexOf(OnboardingStepId id) => order.indexOf(id);

  static OnboardingStepId? next(OnboardingStepId current) {
    final i = indexOf(current);
    if (i == -1 || i >= order.length - 1) return null;
    return order[i + 1];
  }

  static OnboardingStepId? previous(OnboardingStepId current) {
    final i = indexOf(current);
    if (i <= 0) return null;
    return order[i - 1];
  }

  static String analyticsKey(OnboardingStepId id) => id.name;
}