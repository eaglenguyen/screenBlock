import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/paywall/purchase_success_screen.dart';
import 'package:pausenow/paywall/widget/last_chance_offer_sheet.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/constants/hivebox_names.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/premium_provider.dart';
import '../core/analytics/analytics_events.dart';
import '../core/analytics/analytics_service.dart';
import 'widget/all_plans_sheet.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final String source;

  const PaywallScreen({super.key, required this.source});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  String? _error;
  Offerings? _offerings;
  Package? _selectedPackage;

  void _handleClosePressed(BuildContext context) {
    final packages = _offerings?.current?.availablePackages ?? [];
    final lifetime = packages.where((p) => p.packageType == PackageType.lifetime).firstOrNull;

    if (lifetime == null) {
      // no lifetime package available — just close normally
      _markPaywallSeen(context, ref);
      return;
    }

    LastChanceOfferSheet.show(
      context,
      lifetimePackage: lifetime,
      onAccept: () {
        Navigator.pop(context); // close the offer sheet
        setState(() => _selectedPackage = lifetime);
        _purchase();
      },
      onDecline: () {
        Navigator.pop(context); // close the offer sheet
        _markPaywallSeen(context, ref); // then actually leave the paywall
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadOfferings();

    AnalyticsService.instance.capture(
      AnalyticsEvents.paywallViewed,
      {AnalyticsProps.source: widget.source},
    );
  }


  void _showAllPlansSheet(BuildContext context, List<Package> packages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => AllPlansSheet(
        packages: packages,
        selectedPackage: _selectedPackage,
        onSelect: (pkg) => setState(() => _selectedPackage = pkg),
        onPurchase: _purchase,
        isLoading: _isLoading,
      ),
    );
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      setState(() {
        _offerings = offerings;
        _selectedPackage = offerings.current?.annual; // default to annual
      });
    } catch (e) {
      debugPrint('❌ offerings error: $e');
    }
  }

  Future<void> _markPaywallSeen(BuildContext context, WidgetRef ref,
      {bool purchased = false}) async {
    final box = Hive.box(HiveBoxNames.settings);
    await box.put('paywallSeen', true);
    if (purchased) {
      ref.invalidate(premiumProvider);
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (context.mounted) context.go('/home');
  }

  Future<void> _purchase() async {
    if (_selectedPackage == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(_selectedPackage!),
      );
      final isPremium = result.customerInfo.entitlements.active
          .containsKey('pause now Premium');
      if (isPremium && mounted) {
        ref.invalidate(premiumProvider);

        await AnalyticsService.instance.capture(
          AnalyticsEvents.purchaseCompleted,
          {
            AnalyticsProps.source: widget.source,
            AnalyticsProps.plan: _selectedPackage!.packageType.name,
          },
        );

        if (mounted) await PurchaseSuccessScreen.show(context); // 👈 new
        await _markPaywallSeen(context, ref, purchased: true);
      }
    } catch (e) {
      if (e is PurchasesError &&
          e.code != PurchasesErrorCode.purchaseCancelledError) {
        setState(() => _error = 'Purchase failed. Please try again.');
      }
      debugPrint('❌ purchase error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _ctaLabel => ' Start My Free Trial';

  String? _monthlyEquivalent(Package pkg) {
    if (pkg.packageType != PackageType.annual) return null;
    final annualPrice = pkg.storeProduct.price;
    final monthly = annualPrice / 12;
    final symbol = pkg.storeProduct.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${monthly.toStringAsFixed(2)}/month';
  }

  String? _annualDailyLine(Package? annual) {
    if (annual == null) return null;
    final daily = annual.storeProduct.price / 365;
    final symbol = annual.storeProduct.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return 'Then $symbol${daily.toStringAsFixed(2)}/day (${annual.storeProduct.priceString}/year)';
  }

  @override
  Widget build(BuildContext context) {
    final packages = _offerings?.current?.availablePackages ?? [];
    final annual = packages.where((p) => p.packageType == PackageType.annual).firstOrNull;
    final monthly = packages.where((p) => p.packageType == PackageType.monthly).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          // gradient bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a0a3d),
                  Color(0xFF16162a),
                  Color(0xFF0a1a2a),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // close button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => _handleClosePressed(context), // 👈 was () => _markPaywallSeen(context, ref)
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // headline
                        Text(
                          'Start improving\nyour life today',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: 'Join ',
                              style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 14),
                            ),
                            TextSpan(
                              text: '1,000+ ',
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFFEDB82A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text: 'users bettering their lives.',
                              style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 14),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 28),

                        // vertical timeline — unchanged
                        _buildTimeline(),
                      ],
                    ),
                  ),
                ),

                // ── NEW — bottom sheet-style pricing card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E35),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // pricing summary line
                      Column(
                        children: [
                          Text(
                            '7 Days for \$0.00',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (annual != null)
                            Text(
                              _annualDailyLine(annual) ?? '',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Yearly row ──
                      if (annual != null)
                        _PlanRow(
                          label: 'Yearly',
                          price: '${annual.storeProduct.priceString}/year',
                          trialText: '7 days free',
                          badge: '-58%',
                          isSelected: _selectedPackage?.identifier == annual.identifier,
                          onTap: () => setState(() => _selectedPackage = annual),
                        ),
                      if (annual != null && monthly != null)

                        const SizedBox(height: 10),

                      // ── Monthly row ──
                      if (monthly != null)
                        _PlanRow(
                          label: 'Monthly',
                          price: '${monthly.storeProduct.priceString}/month',
                          trialText: '7 days free',
                          isSelected: _selectedPackage?.identifier == monthly.identifier,
                          onTap: () => setState(() => _selectedPackage = monthly),
                        ),
                      const SizedBox(height: 10),

                      // no commitment row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded,
                              color: Color(0xFFEDB82A), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'No payment due now, cancel anytime!',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      // 👇 new

                      const SizedBox(height: 20),

                      // error
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: AppColors.error(context), fontSize: 13)),
                        ),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _purchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEDB82A),
                            foregroundColor: const Color(0xFF1A1208),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: const StadiumBorder(),
                            elevation: 0,
                            textStyle: GoogleFonts.poppins(
                                fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Color(0xFF1A1208), strokeWidth: 2))
                              : Text(_ctaLabel),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Center(
                        child: GestureDetector(
                          onTap: () => _showAllPlansSheet(context, packages),
                          child: Text(
                            'View all plans',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline logic — unchanged from your original ──

  List<_TimelineItem> get _timelineItems {
    final isLifetime = _selectedPackage?.packageType == PackageType.lifetime;

    return [
      _TimelineItem(
        icon: Icons.lock_open_rounded,
        label: 'Today',
        desc: isLifetime
            ? 'All features unlocked instantly.'
            : 'All features unlocked instantly. No charge.',
        isActive: true,
      ),
      _TimelineItem(
        icon: Icons.notifications_none_rounded,
        label: isLifetime ? 'Today' : 'Day 5',
        desc: isLifetime
            ? "We won't send you a reminder since you chose Lifetime."
            : "We'll remind you 2 days before trial ends.",
        isActive: false,
      ),
      _TimelineItem(
        icon: Icons.bolt_rounded,
        label: isLifetime ? 'Today' : 'Day 7',
        desc: isLifetime
            ? 'You will be charged immediately.'
            : 'Cancel 24 hours before in the app store.',
        isActive: false,
      ),
    ];
  }

  Widget _buildTimeline() {
    final items = _timelineItems;

    return Column(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final isLast = i == items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.isActive
                        ? const Color(0xFFEDB82A).withValues(alpha: 0.15)
                        : const Color(0xFF1E1E35),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.isActive
                          ? const Color(0xFFEDB82A)
                          : Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.isActive
                        ? const Color(0xFFEDB82A)
                        : Colors.white.withValues(alpha: 0.3),
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        color: item.isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.desc,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _TimelineItem {
  final IconData icon;
  final String label;
  final String desc;
  final bool isActive;

  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.isActive,
  });
}

// ── New plan row — matches the screenshot's Yearly/Monthly rows ──

class _PlanRow extends StatelessWidget {
  final String label;
  final String price;
  final String? monthlyEquivalent;
  final String trialText;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanRow({
    required this.label,
    required this.price,
    this.monthlyEquivalent,
    required this.trialText,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFEDB82A)
                    : Colors.white.withValues(alpha: 0.12),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      monthlyEquivalent ?? price,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      monthlyEquivalent != null ? price : trialText,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF16162A),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}