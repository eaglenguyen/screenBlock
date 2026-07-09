abstract class SettingsRepository {

  // ── XP / gamification ───────────────────────────
  int getTotalXp();
  Future<void> saveTotalXp(int xp);

  // ── Blocking config ──────────────────────────────
  String getBlockingType();
  List<String> getBlockedApps();
  List<String> getAllowedApps();
  Future<void> saveBlockingConfig({
    required String blockingType,
    required List<String> blockedApps,
    required List<String> allowedApps,
  });

  // ── Screen time / block goals ────────────────────
  double getDailyScreenTimeGoal();
  Future<void> saveDailyScreenTimeGoal(double hours);
  double getDailyBlockGoal();
  Future<void> saveDailyBlockGoal(double hours);

  // ── Review prompt tracking ───────────────────────
  DateTime? getInstallDate();
  bool hasRequestedReview(String key);
  Future<void> markReviewRequested(String key);
}