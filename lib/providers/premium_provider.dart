import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/notification_service.dart';
import '../services/revenuecat_service.dart';
import 'package:flutter/foundation.dart';

bool debugPremiumOverride = false;

Future<void> _scheduleExpiryNotificationIfNeeded(CustomerInfo info) async {
  final entitlement = info.entitlements.all['pause now Premium'];
  if (entitlement == null) return;
  if (!entitlement.isActive) return;

  final expiryDateString = entitlement.expirationDate;
  if (expiryDateString == null) return;

  final expiryDate = DateTime.tryParse(expiryDateString);
  if (expiryDate == null) return;

  final now = DateTime.now();
  final daysUntilExpiry = expiryDate.difference(now).inDays;

  if (daysUntilExpiry > 400) return;

  // cancel existing
  await NotificationService.instance.cancelNotification(99);

  final notifyAt = expiryDate.subtract(const Duration(days: 2));

  final scheduledTime = now.add(const Duration(seconds: 10)); // always fires in 10s


  await NotificationService.instance.scheduleNotification(
    id: 99,
    title: 'Pro subscription expires in 2 days',
    body: 'Renew to keep blocking distractions.',
    scheduledTime: scheduledTime,
  );
}

final premiumProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();

  RevenueCatService.instance.isPremium().then((val) async {
    if (!controller.isClosed) controller.add(val);
    try {
      final info = await Purchases.getCustomerInfo();
      await _scheduleExpiryNotificationIfNeeded(info);
    } catch (e) {
      debugPrint('❌ expiry notification check error: $e');
    }
  });

  Purchases.addCustomerInfoUpdateListener((info) async {
    final isPremium =
    info.entitlements.active.containsKey('pause now Premium');
    if (!controller.isClosed) controller.add(isPremium);
    await _scheduleExpiryNotificationIfNeeded(info);
  });

  ref.onDispose(() => controller.close());

  return controller.stream;
});

final isPremiumProvider = Provider<bool>((ref) {
  if (kDebugMode) return debugPremiumOverride;

  return ref.watch(premiumProvider).when(
    data: (isPremium) => isPremium,
    loading: () => false,
    error: (_, __) => false,
  );
});