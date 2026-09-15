enum OnboardingStepId {
  welcome,
  need,
  gauntletIntro, // 👈 new
  screenTimeGuess, // 👈 new
  gauntletAppsPicker, // 👈 new
  gauntletEquip1, // 👈 new
  gauntletTimeRange, // 👈 new
  gauntletEquip2, // 👈 new
  gauntletDays, // 👈 new
  gauntletEquip3, // 👈 new
  gauntletName, // 👈 new
  gauntletEquip4, // 👈 new
  reassurance,
  neurodivergence,
  name, // 👈 new
  age, // 👈 new
  demoVideo,
}

class OnboardingFlowController {
  OnboardingFlowController._();

  static const List<OnboardingStepId> order = [
    OnboardingStepId.welcome,
    OnboardingStepId.gauntletIntro, // 👈 new
    OnboardingStepId.screenTimeGuess, // 👈 new — gauntlet section right after welcome, per your ask
    OnboardingStepId.gauntletAppsPicker,
    OnboardingStepId.gauntletEquip1,
    OnboardingStepId.gauntletTimeRange,
    OnboardingStepId.gauntletEquip2,
    OnboardingStepId.gauntletDays,
    OnboardingStepId.gauntletEquip3,
    OnboardingStepId.gauntletName,
    OnboardingStepId.gauntletEquip4,
    OnboardingStepId.need,
    OnboardingStepId.reassurance,
    OnboardingStepId.neurodivergence,
    OnboardingStepId.name,
    OnboardingStepId.age,
    OnboardingStepId.demoVideo,


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