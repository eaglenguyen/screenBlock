import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../paywall/purchase_success_screen.dart';
import '../../../providers/premium_provider.dart';


class SettingsUpgradeCard extends ConsumerStatefulWidget {
  const SettingsUpgradeCard({super.key});

  @override
  ConsumerState<SettingsUpgradeCard> createState() => _SettingsUpgradeCardState();
}

class _SettingsUpgradeCardState extends ConsumerState<SettingsUpgradeCard> {
  bool _isLoading = false;
  Package? _annualPackage;

  @override
  void initState() {
    super.initState();
    _loadAnnualPackage();
  }

  Future<void> _loadAnnualPackage() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() => _annualPackage = offerings.current?.annual);
      }
    } catch (e) {
      debugPrint('❌ offerings error: $e');
    }
  }

  Future<void> _startAnnualTrial() async {
    setState(() => _isLoading = true);
    try {
      final annual = _annualPackage ?? (await Purchases.getOfferings()).current?.annual;

      if (annual == null) {
        if (mounted) context.push('/paywall', extra: 'settings_upgrade');
        return;
      }

      final result = await Purchases.purchase(PurchaseParams.package(annual));
      final isPremium = result.customerInfo.entitlements.active
          .containsKey('pause now Premium');

      if (isPremium && mounted) {
        ref.invalidate(premiumProvider);

        await AnalyticsService.instance.capture(
          AnalyticsEvents.purchaseCompleted,
          {
            AnalyticsProps.source: 'settings_upgrade_direct',
            AnalyticsProps.plan: annual.packageType.name,
          },
        );

        if (mounted) await PurchaseSuccessScreen.show(context);
      }
    } catch (e) {
      if (e is PurchasesError &&
          e.code != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('❌ direct purchase error: $e');
        if (mounted) context.push('/paywall', extra: 'settings_upgrade');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── the card, orange gradient ──
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8623D), // deep coral-orange
                Color(0xFFF2A340), // warm orange
                Color(0xFFF7C948), // golden yellow
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.gold(context),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        'assets/icons/pauseIcon.png', // 👈 adjust to your actual asset path
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Try Pause Now Pro',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Includes 1 week of pause now Pro - unlocking every feature for you to try, for free!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startAnnualTrial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: AppColors.goldText(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder( // 👈 was const StadiumBorder()
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.goldText(context),
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Redeem Your Free Week',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9), // 👈 change this to whatever color you want
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 👇 price disclaimer, now directly under the button, inside the card
              Center(
                child: Text(
                  _annualPackage != null
                      ? 'Then ${_annualPackage!.storeProduct.priceString} every year'
                      : 'Then billed annually',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 👇 "Learn More" now sits outside/below the card
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () => context.push('/paywall', extra: 'settings_upgrade'),
            child: Text(
              'Learn More',
              style: GoogleFonts.poppins(
                color: AppColors.gold(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}