class AnalyticsEvents {
  AnalyticsEvents._();

  // lifecycle / activation
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingStepViewed = 'onboarding_step_viewed';
  static const firstBlockCreated = 'first_block_created';
  static const firstSessionCompleted = 'first_session_completed';

  // core loop
  static const blockingSessionStarted = 'blocking_session_started';
  static const blockingSessionCompleted = 'blocking_session_completed';
  static const blockingSessionGivenUp = 'blocking_session_given_up';
  static const pomodoroRoundCompleted = 'pomodoro_round_completed';

  // monetization
  static const paywallViewed = 'paywall_viewed';
  static const paywallDismissed = 'paywall_dismissed';
  static const purchaseCompleted = 'purchase_completed';

  //
  static const firstPomodoroCompleted = 'first_pomodoro_completed';

}

class AnalyticsProps {
  AnalyticsProps._();

  static const stepIndex = 'step_index';
  static const stepName = 'step_name';
  static const source = 'source';
  static const blockingType = 'blocking_type';
  static const durationMinutes = 'duration_minutes';
  static const isPomodoro = 'is_pomodoro';
  static const xpEarned = 'xp_earned';
  static const remainingSeconds = 'remaining_seconds';
  static const roundNumber = 'round_number';
  static const isLongBreak = 'is_long_break';
  static const plan = 'plan';
}

class AnalyticsSources {
  AnalyticsSources._();
  static const pomodoro = 'pomodoro';
  static const blockAllApps = 'block_all_apps';
  static const multipleSchedules = 'multiple_schedules';
  static const multipleSchedulesPreset = 'multiple_schedules_preset';
  static const appLimit = 'app_limit';
  static const lockedScheduleCard = 'locked_schedule_card';

  static const settingsUpgrade = 'settings_upgrade';
  static const onboarding = 'onboarding'; // for PaywallScreen
}