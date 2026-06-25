import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenuecat_service.dart';
import 'package:flutter/foundation.dart'; // 👈 add this import


bool debugPremiumOverride = false; // 👈 global debug flag


final premiumProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();

  RevenueCatService.instance.isPremium().then((val) {
    if (!controller.isClosed) controller.add(val);
  });

  Purchases.addCustomerInfoUpdateListener((info) {
    final isPremium =
    info.entitlements.active.containsKey('pause now Premium');
    if (!controller.isClosed) controller.add(isPremium);
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