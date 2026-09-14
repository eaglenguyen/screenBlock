enum OnboardingStepId {
  welcome,
  need,
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
    OnboardingStepId.need, // 👈 new
    OnboardingStepId.reassurance, // 👈 new
    OnboardingStepId.neurodivergence, // 👈 new
    OnboardingStepId.name, // 👈 new — placed early, adjust position as you like
    OnboardingStepId.age, // 👈 new
    OnboardingStepId.demoVideo, // 👈 new


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