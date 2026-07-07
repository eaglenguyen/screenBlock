import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/constants/hivebox_names.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/premium_provider.dart';
import '../core/analytics/analytics_events.dart';
import '../core/analytics/analytics_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final String source; // 👈 add this

  const PaywallScreen({super.key, required this.source});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  String? _error;
  Offerings? _offerings;
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();

    // 👇 track paywall view with its source
    AnalyticsService.instance.capture(
      AnalyticsEvents.paywallViewed,
      {AnalyticsProps.source: widget.source},
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

        // 👇 track purchase with source + plan
        await AnalyticsService.instance.capture(
          AnalyticsEvents.purchaseCompleted,
          {
            AnalyticsProps.source: widget.source,
            AnalyticsProps.plan: _selectedPackage!.packageType.name,
          },
        );

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

  String get _ctaLabel {
    if (_selectedPackage == null) return 'Try for \$0.00';
    final type = _selectedPackage!.packageType;
    if (type == PackageType.lifetime) return 'Get Lifetime Access';
    return 'Try for \$0.00';
  }

  String get _priceSubtitle {
    if (_selectedPackage == null) return '';
    final type = _selectedPackage!.packageType;
    final price = _selectedPackage!.storeProduct.priceString;
    if (type == PackageType.annual) return '7 days free, then $price/year. Cancel 24 hours before in the app store.';
    if (type == PackageType.monthly) return '7 days free, then $price/month. Cancel 24 hours before in the app store.';
    return 'One-time payment of $price. No subscription.';
  }

  @override
  Widget build(BuildContext context) {
    final packages = _offerings?.current?.availablePackages ?? [];
    final annual = packages.where((p) => p.packageType == PackageType.annual).firstOrNull;
    final monthly = packages.where((p) => p.packageType == PackageType.monthly).firstOrNull;
    final lifetime = packages.where((p) => p.packageType == PackageType.lifetime).firstOrNull;

    // helper to calculate monthly equivalent
    String? monthlyEquivalent(Package pkg) {
      if (pkg.packageType != PackageType.annual) return null;
      final annualPrice = pkg.storeProduct.price;
      final monthly = annualPrice / 12;
      // format with same currency symbol
      final symbol = pkg.storeProduct.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
      return '$symbol${monthly.toStringAsFixed(2)}/mo';
    }

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // close button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _markPaywallSeen(context, ref),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white54, size: 18),
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
                        text: 'users reclaiming their focus.',
                        style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // vertical timeline
                  _buildTimeline(),
                  const SizedBox(height: 28),

                  // plan cards
                  if (packages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (monthly != null)
                          Expanded(
                            child: _PlanCard(
                              label: 'Monthly',
                              price: monthly.storeProduct.priceString,
                              period: '/mo',
                              badge: "7-day free trial",
                              isSelected: _selectedPackage?.identifier == monthly.identifier,
                              onTap: () => setState(() => _selectedPackage = monthly),
                            ),
                          ),
                        if (monthly != null && annual != null)
                          const SizedBox(width: 10),
                        if (annual != null)
                          Expanded(
                            child: _PlanCard(
                              label: 'Annual',
                              price: annual.storeProduct.priceString,
                              period: '/yr',
                              badge: '7-day free trial',
                              monthlyEquivalent: monthlyEquivalent(annual), // 👈
                              isSelected: _selectedPackage?.identifier == annual.identifier,
                              onTap: () => setState(() => _selectedPackage = annual),
                            ),
                          ),
                      ],
                    ),
                    if (lifetime != null) ...[
                      const SizedBox(height: 10),
                      _PlanCard(
                        label: 'Lifetime',
                        price: lifetime.storeProduct.priceString,
                        period: ' one-time',
                        badge: "BEST VALUE",
                        isSelected: _selectedPackage?.identifier == lifetime.identifier,
                        onTap: () => setState(() => _selectedPackage = lifetime),
                        fullWidth: true,
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),

                  // no commitment row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Color(0xFFEDB82A), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'No payment due now!',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 8),
                  Text(
                    _priceSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        label: isLifetime ? 'Today' : 'Day 5', // 👈
        desc: isLifetime
            ? "We won't send you a reminder since you chose Lifetime."
            : "We'll remind you 2 days before trial ends.",
        isActive: false,
      ),
      _TimelineItem(
        icon: Icons.bolt_rounded,
        label: isLifetime ? 'Today' : 'Day 7', // 👈
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
            // icon + line
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

            // text
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

// ── Plan Card ─────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String period;
  final String? badge;
  final String? monthlyEquivalent;
  final bool isSelected;
  final VoidCallback onTap;
  final bool fullWidth;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.period,
    required this.badge,
    this.monthlyEquivalent,
    required this.isSelected,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEDB82A).withValues(alpha: 0.08)
              : const Color(0xFF1E1E35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEDB82A)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (badge != null)
              Positioned(
                top: -26,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEDB82A)
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.poppins(
                      color: isSelected
                          ? const Color(0xFF1A1208)
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

            Row(
              mainAxisAlignment: fullWidth
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: isSelected ? const Color(0xFFEDB82A) : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (monthlyEquivalent != null) ...[
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: price,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: period,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '($monthlyEquivalent)',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                    else
                    // 👇 normal price for monthly and lifetime
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: price,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: period,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),

      ),

    );


  }
}
