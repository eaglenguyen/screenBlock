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
      _markPaywallSeen(context, ref);
      return;
    }
    LastChanceOfferSheet.show(
      context,
      lifetimePackage: lifetime,
      onAccept: () {
        Navigator.pop(context);
        setState(() => _selectedPackage = lifetime);
        _purchase();
      },
      onDecline: () {
        Navigator.pop(context);
        _markPaywallSeen(context, ref);
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
        _selectedPackage = offerings.current?.annual;
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
        if (mounted) await PurchaseSuccessScreen.show(context);
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

  String get _ctaLabel => 'Start My 7-Day Free Trial';
  String get _billingDate {
    final date = DateTime.now().add(const Duration(days: 7));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _monthlyEquivalent(Package pkg) {
    final monthly = pkg.storeProduct.price / 12;
    final symbol = pkg.storeProduct.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${monthly.toStringAsFixed(2)}/mo';
  }

  @override
  Widget build(BuildContext context) {
    final packages = _offerings?.current?.availablePackages ?? [];
    final annual = packages.where((p) => p.packageType == PackageType.annual).firstOrNull;
    final monthly = packages.where((p) => p.packageType == PackageType.monthly).firstOrNull;
    final isAnnualSelected = _selectedPackage?.packageType == PackageType.annual;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a0a3d), Color(0xFF16162a), Color(0xFF0a1a2a)],
                stops: [0.0, 0.5, 1.0],
              )
                  : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.background(context), AppColors.background(context)],
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => _handleClosePressed(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundSubtle(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded, color: AppColors.textSecondary(context), size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Start your 7-day FREE\ntrial to continue.',
                          style: GoogleFonts.poppins(
                            color: AppColors.textPrimary(context),
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildTimeline(context),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard(context),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (monthly != null)
                            Expanded(
                              child: _PlanCard(
                                label: 'Monthly',
                                price: monthly.storeProduct.priceString,
                                period: '/mo',
                                isSelected: _selectedPackage?.identifier == monthly.identifier,
                                onTap: () => setState(() => _selectedPackage = monthly),
                              ),
                            ),
                          if (monthly != null && annual != null) const SizedBox(width: 12),
                          if (annual != null)
                            Expanded(
                              child: _PlanCard(
                                label: 'Yearly',
                                price: annual.storeProduct.priceString,
                                period: '/yr',
                                badge: '7-Days FREE',
                                isSelected: _selectedPackage?.identifier == annual.identifier,
                                onTap: () => setState(() => _selectedPackage = annual),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, color: AppColors.accent(context), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'No Payment Due Now',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary(context),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: AppColors.error(context), fontSize: 13)),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _purchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent(context),
                            foregroundColor: AppColors.accentText(context),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: const StadiumBorder(),
                            elevation: 0,
                            textStyle: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          child: _isLoading
                              ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: AppColors.accentText(context), strokeWidth: 2))
                              : Text(_ctaLabel),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAnnualSelected && annual != null
                            ? '7 days free, then ${annual.storeProduct.priceString} per year (${_monthlyEquivalent(annual)})'
                            : monthly != null
                            ? '7 days free, then ${monthly.storeProduct.priceString} per month'
                            : '',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: () => _showAllPlansSheet(context, packages),
                          child: Text(
                            'View all plans',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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

  List<_TimelineItem> _timelineItems(BuildContext context) {
    return [
      _TimelineItem(
        icon: Icons.lock_open_rounded,
        label: 'Today',
        desc: 'Unlock all the app\'s features instantly.',
        color: AppColors.accent(context),
      ),
      _TimelineItem(
        icon: Icons.notifications_none_rounded,
        label: 'In 2 Days - Reminder',
        desc: 'We\'ll send you a reminder that your trial is ending soon.',
        color: AppColors.accent(context),
      ),
      _TimelineItem(
        icon: Icons.workspace_premium_rounded,
        label: 'In 7 Days - Billing Starts',
        desc: 'You\'ll be charged on $_billingDate unless you cancel anytime before.',
        color: AppColors.backgroundSubtle(context),
        iconColor: AppColors.textSecondary(context),
      ),
    ];
  }

  Widget _buildTimeline(BuildContext context) {
    final items = _timelineItems(context);
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
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor ?? AppColors.accentText(context),
                    size: 16,
                  ),
                ),
                Container(
                  width: 10,
                  height: isLast ? 30 : 80,
                  color: AppColors.accent(context).withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.desc,
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary(context),
                        fontSize: 15,
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
  final Color color;
  final Color? iconColor;
  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    this.iconColor,
  });
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String period;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;
  const _PlanCard({
    required this.label,
    required this.price,
    required this.period,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.accent(context) : AppColors.border(context),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: price,
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: period,
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.poppins(
                      color: AppColors.accentText(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}