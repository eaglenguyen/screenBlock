// lib/onboarding_new/screens/onboarding_paywall_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../providers/premium_provider.dart'; // adjust path to match your actual location

class OnboardingPaywallScreen extends ConsumerStatefulWidget {
  final VoidCallback onContinue; // called after purchase success OR if they skip/decline

  const OnboardingPaywallScreen({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<OnboardingPaywallScreen> createState() => _OnboardingPaywallScreenState();
}

class _OnboardingPaywallScreenState extends ConsumerState<OnboardingPaywallScreen> {
  bool _isLoading = false;
  bool _isRestoring = false;
  Package? _annualPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() => _annualPackage = offerings.current?.annual);
      }
    } catch (e) {
      debugPrint('❌ offerings error: $e');
    }
  }

  Future<void> _startTrial() async {
    widget.onContinue(); // 👈 was: full purchase flow — now just advances immediately
  }

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPremium = customerInfo.entitlements.active.containsKey('pause now Premium');
      if (isPremium) {
        ref.invalidate(premiumProvider);
      }
    } catch (e) {
      debugPrint('❌ restore error: $e');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  String get _priceLabel {
    if (_annualPackage == null) return 'Just \$29.99 per year';
    return 'Just ${_annualPackage!.storeProduct.priceString} per year';
  }

  String get _monthlyEquivalent {
    if (_annualPackage == null) return '\$2.49/mo';
    final monthly = _annualPackage!.storeProduct.price / 12;
    final symbol = _annualPackage!.storeProduct.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${monthly.toStringAsFixed(2)}/mo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _isRestoring ? null : _restorePurchases,
                  child: Text(
                    _isRestoring ? 'Restoring...' : 'Restore',
                    style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'We want you to\ntry SpinBrek for free.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF4A3728),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 60),
                      _featureRow(
                        title: 'Unlimited Wheel Spins',
                        subtitle: 'Think twice before unblocking your apps, spin the wheel and do something else',
                      ),
                      const SizedBox(height: 20),
                      _featureRow(
                        title: 'No Account or Signup needed!',
                        subtitle: 'All of your schedules and task list for the wheel are saved on your device!',
                      ),
                      const SizedBox(height: 20),
                      _featureRow(
                        title: 'Strict and Hard mode',
                        subtitle: 'For users who are ACTUALLY committed to make a change, no edits or pausing allowed',
                      ),
                      const SizedBox(height: 20),
                      _featureRow(
                        title: 'No Ads',
                        subtitle: 'No pesky ad banners to disturb your peace',
                      ),
                      const SizedBox(height: 60),
                      Text(
                        '★★★★★',
                        style: GoogleFonts.poppins(color: const Color(0xFFF8D35A), fontSize: 22, letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Loved by thousands of users',
                        style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, color: const Color(0xFF2D7A54), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'No Payment Due Now',
                    style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startTrial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A3728),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const StadiumBorder(),
                    textStyle: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Try for \$0.00'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_priceLabel ($_monthlyEquivalent)',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2D7A54), size: 24), // 👈 was 22
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 19, fontWeight: FontWeight.w700), // 👈 was 17
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 14, height: 1.3), // 👈 was 13
              ),
            ],
          ),
        ),
      ],
    );
  }
}