import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/paywall/purchase_success_screen.dart';
import 'package:pausenow/paywall/widget/all_plans_sheet.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/constants/hivebox_names.dart';
import '../../providers/premium_provider.dart';
import '../../core/theme/app_colors.dart';
import '../core/analytics/analytics_events.dart';
import '../core/analytics/analytics_service.dart';

class FeaturePaywallScreen extends ConsumerStatefulWidget {
  final String source;
  const FeaturePaywallScreen({super.key, required this.source});
  @override
  ConsumerState<FeaturePaywallScreen> createState() => _FeaturePaywallScreenState();
}

class _FeaturePaywallScreenState extends ConsumerState<FeaturePaywallScreen> {
  bool _isLoading = false;
  String? _error;
  Offerings? _offerings;
  Package? _selectedPackage;

  final List<_FeatureItem> _features = [
    _FeatureItem(label: 'Manual blocking', free: true, pro: true),
    _FeatureItem(label: '1 schedule', free: true, pro: true),
    _FeatureItem(label: '3 apps per block session', free: true, pro: true),
    _FeatureItem(label: 'Unlimited schedules', free: false, pro: true),
    _FeatureItem(label: 'Unlimited apps per session', free: false, pro: true),
    _FeatureItem(label: '\'Block All Apps\' Mode', free: false, pro: true),
    _FeatureItem(label: 'Time & Open Limits', free: false, pro: true),
    _FeatureItem(label: 'Pomodoro Mode 🍅', free: false, pro: true),
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
    AnalyticsService.instance.capture(
      AnalyticsEvents.paywallViewed,
      {AnalyticsProps.source: widget.source},
    );
  }

  void _showAllPlansSheet(List<Package> packages) {
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

  String get _renewalText {
    if (_selectedPackage == null) return '';
    final type = _selectedPackage!.packageType;
    final price = _selectedPackage!.storeProduct.priceString;
    if (type == PackageType.lifetime) return 'One-time payment of $price';
    if (type == PackageType.annual) return 'Then $price every year';
    return 'Then $price every month';
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

  Future<void> _purchase() async {
    if (_selectedPackage == null) return;
    setState(() { _isLoading = true; _error = null; });
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
        final box = Hive.box(HiveBoxNames.settings);
        await box.put('paywallSeen', true);
        if (mounted) await PurchaseSuccessScreen.show(context);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
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

  String? _monthlyEquivalent(Package pkg) {
    if (pkg.packageType != PackageType.annual) return null;
    final monthly = pkg.storeProduct.price / 12;
    final symbol = pkg.storeProduct.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${monthly.toStringAsFixed(2)}/mo';
  }

  String get _ctaLabel {
    if (_selectedPackage?.packageType == PackageType.lifetime) return 'Get Lifetime Access';
    return 'Redeem Your Free Week';
  }

  @override
  Widget build(BuildContext context) {
    final packages = _offerings?.current?.availablePackages ?? [];
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'pause now ',
                            style: TextStyle(color: AppColors.textPrimary(context)),
                          ),
                          TextSpan(
                            text: 'Free',
                            style: TextStyle(color: AppColors.textSecondary(context)),
                          ),
                          WidgetSpan(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'vs ',
                                      style: TextStyle(
                                        color: AppColors.textSecondary(context),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'pause now ',
                                      style: TextStyle(color: AppColors.accent(context)),
                                    ),
                                    WidgetSpan(
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent(context),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Pro',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.accentText(context),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonTable(context),
                  const SizedBox(height: 28),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: AppColors.error(context), fontSize: 13)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _purchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent(context),
                        foregroundColor: AppColors.accentText(context),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        textStyle: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      child: _isLoading
                          ? SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.accentText(context), strokeWidth: 2))
                          : Text(_ctaLabel),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _renewalText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                    ),
                  ),
                  if (packages.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: () => _showAllPlansSheet(packages),
                        child: Text(
                          'View all plans',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Positioned(
            top: 36,
            right: 24,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSubtle(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, color: AppColors.textPrimary(context), size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent(context).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.backgroundSubtle(context),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Center(
                        child: Text('Free',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Pro',
                              style: GoogleFonts.poppins(
                                color: AppColors.accentText(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(_features.length, (i) {
                final f = _features[i];
                final isLast = i == _features.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: i % 2 == 0
                        ? AppColors.backgroundCard(context)
                        : AppColors.background(context),
                    border: isLast
                        ? null
                        : Border(
                      bottom: BorderSide(
                        color: AppColors.border(context),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(f.label,
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                      SizedBox(
                        width: 64,
                        child: Center(child: _statusIcon(context, f.free, false)),
                      ),
                      SizedBox(
                        width: 64,
                        child: Center(child: _statusIcon(context, f.pro, true)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusIcon(BuildContext context, bool included, bool isPro) {
    if (included) {
      return Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: isPro ? AppColors.accent(context) : AppColors.success(context),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded,
            color: isPro ? AppColors.accentText(context) : Colors.white, size: 15),
      );
    } else {
      return Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: AppColors.error(context),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
      );
    }
  }
}

class _FeatureItem {
  final String label;
  final bool free;
  final bool pro;
  const _FeatureItem({required this.label, required this.free, required this.pro});
}