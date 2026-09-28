// lib/paywall/paywall_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pausenow/paywall/widget/all_plans_sheet.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../core/constants/hivebox_names.dart';
import '../onboarding_new/widget/wheel_demo.dart';
import '../providers/premium_provider.dart';
import '../core/analytics/analytics_events.dart';
import '../core/analytics/analytics_service.dart';
import 'purchase_success_screen.dart';
import 'widget/last_chance_offer_sheet.dart';

// ── Theme ─────────────────────────────────────────────
const _bg = Color(0xFFFFF7ED);
const _card = Colors.white;
const _border = Color(0xFFF0E6D8);
const _text = Color(0xFF4A3728);
const _textSub = Color(0xFFB08A5A);
const _mintDark = Color(0xFF2D7A54);
const _pro = Color(0xFFF2A340); // 👈 swap to Color(0xFF7DD3B0) if you'd rather the CTA be mint
const _gold = Color(0xFFF8D35A);

// ── Social proof — ⚠️ replace with your REAL numbers and reviews before shipping ──
const _ratingValue = '4.9';
const _userCount = '10k+';
const _reviews = [
  ('Maya, 22', 'Student', 'Actually works', 'I used to lose hours on TikTok before bed. Now I spin the wheel and end up reading instead. Wild.'),
  ('Jordan R.', 'Designer', 'Better than Screen Time', 'Screen Time limits I just tapped "ignore." The wheel makes me stop and think. Huge difference.'),
  ('Priya S.', 'Nurse', 'My phone habit is gone', 'I set a schedule for work hours and haven\'t doomscrolled on shift in weeks.'),
];

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
  bool _showCloseButton = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
    AnalyticsService.instance.capture(AnalyticsEvents.paywallViewed, {AnalyticsProps.source: widget.source});
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showCloseButton = true);
    });
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _selectedPackage = offerings.current?.annual;
        });
      }
    } catch (e) {
      debugPrint('❌ offerings error: $e');
    }
  }

  Future<void> _markPaywallSeen({bool purchased = false}) async {
    final box = Hive.box(HiveBoxNames.settings);
    await box.put('paywallSeen', true);
    if (purchased) {
      ref.invalidate(premiumProvider);
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (mounted) context.go('/home');
  }

  void _handleClose() {
    final packages = _offerings?.current?.availablePackages ?? [];
    final lifetime = packages.where((p) => p.packageType == PackageType.lifetime).firstOrNull;
    if (lifetime == null) {
      _markPaywallSeen();
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
        _markPaywallSeen();
      },
    );
  }

  Future<void> _purchase() async {
    if (_selectedPackage == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await Purchases.purchase(PurchaseParams.package(_selectedPackage!));
      final isPremium = result.customerInfo.entitlements.active.containsKey('pause now Premium');
      if (isPremium && mounted) {
        await AnalyticsService.instance.capture(AnalyticsEvents.purchaseCompleted, {
          AnalyticsProps.source: widget.source,
          AnalyticsProps.plan: _selectedPackage!.packageType.name,
        });
        if (mounted) await PurchaseSuccessScreen.show(context);
        await _markPaywallSeen(purchased: true);
      }
    } catch (e) {
      if (e is PurchasesError && e.code != PurchasesErrorCode.purchaseCancelledError) {
        setState(() => _error = 'Purchase failed. Please try again.');
      }
      debugPrint('❌ purchase error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore() async {
    try {
      final info = await Purchases.restorePurchases();
      if (info.entitlements.active.containsKey('pause now Premium')) {
        await _markPaywallSeen(purchased: true);
      }
    } catch (e) {
      debugPrint('❌ restore error: $e');
    }
  }

  String get _billingDate =>
      DateFormat('MMM d, yyyy').format(DateTime.now().add(const Duration(days: 7)));

  Widget _buildTimeline() {
    final items = [
      (Icons.lock_open_rounded, 'Today', "Unlock all of Spinbrek Pro's features instantly.", true),
      (Icons.notifications_none_rounded, 'In 2 Days - Reminder', "We'll send you a reminder that your trial is ending soon.", true),
      (Icons.workspace_premium_rounded, 'In 7 Days - Billing Starts',
      "You'll be charged on $_billingDate unless you cancel anytime before.", false),
    ];

    return Column(
      children: List.generate(items.length, (i) {
        final (icon, label, desc, active) = items[i];
        final isLast = i == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: active ? _pro : _border,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: active ? Colors.white : _textSub, size: 18),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 8,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: _pro.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: GoogleFonts.poppins(color: _text, fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(desc, style: GoogleFonts.poppins(color: _textSub, fontSize: 14, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Derived values ──────────────────────────────────
  Package? get _annual => _offerings?.current?.annual;
  Package? get _monthly => _offerings?.current?.monthly;

  bool get _isMonthlySelected => _selectedPackage?.packageType == PackageType.monthly;

  String get _ctaLabel => _isMonthlySelected ? 'Subscribe Now' : 'Try for \$0.00';

  String get _finePrint {
    if (_isMonthlySelected) {
      return '7 days free, then ${_monthly?.storeProduct.priceString ?? ''} billed monthly. Cancel anytime.';
    }
    return '7 days free, then ${_annual?.storeProduct.priceString ?? '\$19.99'} per year ($_monthlyEquivalent) billed automatically.';
  }

  void _showAllPlansSheet() {
    final packages = _offerings?.current?.availablePackages ?? [];
    if (packages.isEmpty) return;
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

  String get _weeklyPrice {
    final a = _annual;
    if (a == null) return '\$0.38';
    final symbol = a.storeProduct.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${(a.storeProduct.price / 52).toStringAsFixed(2)}';
  }

  String get _monthlyEquivalent {
    final a = _annual;
    if (a == null) return '\$1.67/mo';
    final symbol = a.storeProduct.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${(a.storeProduct.price / 12).toStringAsFixed(2)}/mo';
  }

  String get _goalDate => DateFormat('MMM d, yyyy').format(DateTime.now().add(const Duration(days: 30)));

  // ── Build ───────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 56, 22, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 28),
                        AnimatedSize( // 👈 replaces _buildStatsRow() + SizedBox(32) + _buildGoalDate()
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: _buildTimeline(),
                        ),
                        const SizedBox(height: 32),
                        _buildChecklist(),
                        const SizedBox(height: 20),
                        Row( // 👈 new — just the stars
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: _gold, size: 26)),
                        ),
                        const SizedBox(height: 32),
                        _buildQuote(_reviews[0].$4, _reviews[0].$1),
                        const SizedBox(height: 32),
                        _buildFeatures(),
                        const SizedBox(height: 36),
                        _sectionTitle('See What Others Say'),
                        const SizedBox(height: 16),
                        _buildReviewCarousel(),
                        const SizedBox(height: 36),
                        _buildComparisonTable(),
                        const SizedBox(height: 36),
                        _buildRatingCard(),
                        const SizedBox(height: 32),
                        _buildGoalDate(),
                        const SizedBox(height: 36),
                        _sectionTitle('Frequently Asked Questions'),
                        const SizedBox(height: 12),
                        const _FaqList(),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 16,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _showCloseButton ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_showCloseButton,
                        child: GestureDetector(
                          onTap: _handleClose,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: _card, shape: BoxShape.circle, border: Border.all(color: _border)),
                            child: const Icon(Icons.close_rounded, color: _textSub, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildStickyFooter(),
          ],
        ),
      ),
    );
  }

  // ── Sections ────────────────────────────────────────
  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded( // 👈 lets the headline wrap instead of pushing the wheel off-screen
              child: Text(
              'Become the more productive version of yourself with Spinbrek', // 👈 keep whatever headline text you currently have
                style: GoogleFonts.poppins(color: _text, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.8),
              ),
            ),
            const SizedBox(width: 12),
            const MiniWheelPreview(showLabel: false), // 👈 new
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Break the doomscroll habit in 30 days with schedules, strict mode, and the wheel!',
          style: GoogleFonts.poppins(color: _textSub, fontSize: 15, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _laurelStat(_ratingValue, 'average\nrating'),
        _laurelStat(_userCount, 'users\nworldwide'),
      ],
    );
  }

  Widget _laurelStat(String value, String label) {
    return Row(
      children: [
        Transform.flip(flipX: true, child: const Icon(Icons.spa_rounded, color: _gold, size: 30)),
        const SizedBox(width: 6),
        Column(
          children: [
            Text(value, style: GoogleFonts.poppins(color: _text, fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: _textSub, fontSize: 11, height: 1.2)),
          ],
        ),
        const SizedBox(width: 6),
        const Icon(Icons.spa_rounded, color: _gold, size: 30),
      ],
    );
  }

  Widget _buildGoalDate() {
    return Column(
      children: [
        Text(
          "You'll have your time back by:",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: _text, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _pro.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _pro, width: 2),
          ),
          child: Text(_goalDate, style: GoogleFonts.poppins(color: _text, fontSize: 17, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _buildChecklist() {
    const items = [
      'Stop reaching for your phone on autopilot',
      'Get hours back every single week',
      'Actually finish what you start',
      'Sleep better without late-night scrolling',
      'Feel in control of your phone, not the other way around',
    ];
    return Column(
      children: items
          .map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_rounded, color: _mintDark, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: GoogleFonts.poppins(color: _text, fontSize: 15, height: 1.35))),
          ],
        ),
      ))
          .toList(),
    );
  }

  Widget _buildQuote(String quote, String author) {
    return Column(
      children: [
        Text(
          '"$quote"',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: _text, fontSize: 16, fontStyle: FontStyle.italic, height: 1.5),
        ),
        const SizedBox(height: 8),
        Text('— $author', style: GoogleFonts.poppins(color: _textSub, fontSize: 13)),
      ],
    );
  }

  Widget _buildFeatures() {
    const features = [
      (Icons.all_inclusive_rounded, 'Unlimited schedules & apps', 'Block as many apps, as many times a day, as you need.'),
      (Icons.autorenew_rounded, 'Unlimited wheel spins', 'Always have something better to do than scroll.'),
      (Icons.lock_rounded, 'Strict & Hard mode', 'No pausing, no editing, no escape hatches.'),
      (Icons.timer_rounded, 'Lock apps & time limits', 'Cap unlocks per day or daily minutes per app.'),
    ];
    return Column(
      children: features
          .map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: _pro.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(f.$1, color: _pro, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.$2, style: GoogleFonts.poppins(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(f.$3, style: GoogleFonts.poppins(color: _textSub, fontSize: 13.5, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    textAlign: TextAlign.center,
    style: GoogleFonts.poppins(color: _text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
  );

  Widget _buildReviewCarousel() {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = _reviews[i];
          return Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.$1, style: GoogleFonts.poppins(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
                Text(r.$2, style: GoogleFonts.poppins(color: _textSub, fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: _gold, size: 18))),
                const SizedBox(height: 6),
                Text(r.$3, style: GoogleFonts.poppins(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(r.$4, style: GoogleFonts.poppins(color: _textSub, fontSize: 13, height: 1.4), overflow: TextOverflow.fade),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonTable() {
    final rows = [
      ('Cost', '$_weeklyPrice \na week', '\$4.50 \na cup', '\$200+ \na session'),
      ('Healthy', true, false, true),
      ('Cute', true, true, false),
      ('Fun', true, false, false),
    ];
    Widget header(String t, {bool highlight = false}) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: highlight
            ? BoxDecoration(color: _pro.withValues(alpha: 0.12), borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))
            : null,
        child: Text(t,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: highlight ? _text : _textSub, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
    Widget cell(Object v, {bool highlight = false}) => Expanded(
      child: Container(
        height: 48,
        color: highlight ? _pro.withValues(alpha: 0.12) : null,
        alignment: Alignment.center,
        child: v is bool
            ? Icon(v ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: v ? _mintDark : _textSub.withValues(alpha: 0.6), size: 22)
            : Text('$v',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: _text, fontSize: 13, fontWeight: highlight ? FontWeight.w800 : FontWeight.w500)),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: Column(
        children: [
          Row(children: [
            const Expanded(flex: 2, child: SizedBox()),
            header('Spinbrek', highlight: true),
            header('Starbuck'),
            header('Therapy'),
          ]),
          ...rows.map((r) => Row(children: [
            Expanded(
              flex: 2,
              child: Text(r.$1, style: GoogleFonts.poppins(color: _text, fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
            cell(r.$2, highlight: true),
            cell(r.$3),
            cell(r.$4),
          ])),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
      child: Column(
        children: [
          Text('Join thousands of people\ntaking their time back',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: _text, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 14),
          Text('Average Rating', style: GoogleFonts.poppins(color: _textSub, fontSize: 13)),
          Text(_ratingValue, style: GoogleFonts.poppins(color: _text, fontSize: 32, fontWeight: FontWeight.w800)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: _gold, size: 26)),
          ),
        ],
      ),
    );
  }

  // ── Sticky footer ───────────────────────────────────
  Widget _buildStickyFooter() {
    final annual = _annual;
    final monthly = _monthly;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: _bg,
        border: const Border(top: BorderSide(color: _border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isMonthlySelected)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_rounded, color: _mintDark, size: 16),
                  const SizedBox(width: 6),
                  Text('Try risk-free. Cancel anytime before your trial ends.',
                      style: GoogleFonts.poppins(color: _textSub, fontSize: 12)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8), // room for the badge above the Yearly card
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (monthly != null)
                  Expanded(
                    child: _planCard(
                      label: 'Monthly',
                      price: monthly.storeProduct.priceString,
                      sub: 'per month',
                      isSelected: _selectedPackage?.identifier == monthly.identifier,
                      onTap: () => setState(() => _selectedPackage = monthly),
                    ),
                  ),
                if (monthly != null && annual != null) const SizedBox(width: 10),
                if (annual != null)
                  Expanded(
                    child: _planCard(
                      label: 'Yearly',
                      price: annual.storeProduct.priceString,
                      sub: _monthlyEquivalent,
                      badge: '7 DAYS FREE',
                      isSelected: _selectedPackage?.identifier == annual.identifier,
                      onTap: () => setState(() => _selectedPackage = annual),
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: GoogleFonts.poppins(color: Colors.red.shade400, fontSize: 13)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _purchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pro,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _pro.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_ctaLabel, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_finePrint,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: _textSub, fontSize: 11, height: 1.3)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showAllPlansSheet,
            child: Text(
              'View all plans',
              style: GoogleFonts.poppins(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: _text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required String label,
    required String price,
    required String sub,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _pro.withValues(alpha: 0.08) : _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? _pro : _border, width: isSelected ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(price, style: GoogleFonts.poppins(color: _text, fontSize: 17, fontWeight: FontWeight.w800)),
                Text(sub, style: GoogleFonts.poppins(color: _textSub, fontSize: 12)),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _pro, borderRadius: BorderRadius.circular(20)),
                child: Text(badge,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }


  Widget _footerLink(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Text(label, style: GoogleFonts.poppins(color: _textSub, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text('·', style: GoogleFonts.poppins(color: _textSub, fontSize: 12)),
  );
}

// ── FAQ accordion ───────────────────────────────────────
class _FaqList extends StatefulWidget {
  const _FaqList();
  @override
  State<_FaqList> createState() => _FaqListState();
}

class _FaqListState extends State<_FaqList> {
  int? _open = 0;

  static const _faqs = [
    ('Does SpinBrek actually work?',
    'Yes. Instead of a limit you can dismiss with one tap, SpinBrek interrupts the habit and gives you something better to do. That pause is what breaks the autopilot.'),
    ('Is SpinBrek right for me?',
    'If you open apps without meaning to, lose track of time scrolling, or feel worse after using your phone, SpinBrek is built for you.'),
    ('Can I cancel during the trial?',
    'Yes. You have 7 days to try every Pro feature. Cancel anytime before the trial ends in your App Store / Play Store subscriptions and you won\'t be charged.'),
    ('Is my data private?',
    'SpinBrek needs no account. Your schedules and wheel lists stay on your device, and Screen Time data never leaves your phone.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_faqs.length, (i) {
        final isOpen = _open == i;
        return GestureDetector(
          onTap: () => setState(() => _open = isOpen ? null : i),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(color: _pro, shape: BoxShape.circle),
                      child: AnimatedRotation(
                        turns: isOpen ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_faqs[i].$1,
                          style: GoogleFonts.poppins(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: isOpen
                      ? Padding(
                    padding: const EdgeInsets.only(left: 34, top: 8),
                    child: Text(_faqs[i].$2, style: GoogleFonts.poppins(color: _textSub, fontSize: 14, height: 1.5)),
                  )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}