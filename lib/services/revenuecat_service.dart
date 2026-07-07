import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService._();
  static final instance = RevenueCatService._();

  static const _iosApiKey = 'appl_sGiWZFRTsStgZHfTJKWClTYWWko';
  static const _androidApiKey = 'goog_MnWEimkWbZdzyQAMTHfZPImmMyX';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await Purchases.setLogLevel(
      kDebugMode ? LogLevel.debug : LogLevel.error,
    );

    // 👇 use correct key per platform
    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
    final config = PurchasesConfiguration(apiKey);
    await Purchases.configure(config);
    await Purchases.invalidateCustomerInfoCache();

    _initialized = true;
    debugPrint('✅ RevenueCat initialized (${Platform.isIOS ? 'iOS' : 'Android'})');
  }

  Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('pause now Premium');
    } catch (e) {
      debugPrint('❌ isPremium error: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey('pause now Premium');
    } catch (e) {
      debugPrint('❌ restorePurchases error: $e');
      return false;
    }
  }
}