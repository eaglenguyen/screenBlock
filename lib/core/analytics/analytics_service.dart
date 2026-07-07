import 'package:hive/hive.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../constants/hivebox_names.dart';
import 'analytics_events.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  Future<void> capture(String event, [Map<String, Object>? properties]) {
    return Posthog().capture(eventName: event, properties: properties);
  }

  /// Fires [event] only the first time ever, using a Hive flag to dedupe.
  Future<void> captureOnce(String event, {Map<String, Object>? properties}) async {
    final box = Hive.box(HiveBoxNames.settings);
    final key = 'analytics_fired_$event';
    if (box.get(key, defaultValue: false) == false) {
      await capture(event, properties);
      await box.put(key, true);
    }
  }

  Future<void> identifyPremiumUser({required String plan}) async {
    await Posthog().identify(
      userId: await Purchases.appUserID,
      userProperties: {
        'is_premium': true,
        AnalyticsProps.plan: plan,
      },
    );
  }
}