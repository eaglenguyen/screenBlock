class AppConstants {
  AppConstants._();

  // ── Timer presets (minutes) ────────────────────
  static const List<int> timerPresets = [5, 10, 15, 30, 60];

  // ── Block intensity ────────────────────────────
  static const String softBlock   = 'soft';
  static const String mediumBlock = 'medium';
  static const String hardBlock   = 'hard';

  // ── Free tier limits ──────────────────────────
  static const int freeTrackedAppsLimit = 2;

  // ── Foreground poll interval ──────────────────
  static const int pollIntervalMs = 1000;

  // ── Hive type IDs ─────────────────────────────
  static const int timerConfigTypeId  = 0;
  static const int blockedAppTypeId   = 1;
  static const int usageLogTypeId     = 2;
  static const int streakTypeId       = 3;

  // app_constants.dart — add
  static const int scheduleTypeId = 4;

// blocking types
  static const String blockingTypeAllApps      = 'all_apps';
  static const String blockingTypeSpecificApps = 'specific_apps';
}