import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class AllPlansSheet extends StatefulWidget {
  final List<Package> packages;
  final Package? selectedPackage;
  final ValueChanged<Package> onSelect;
  final VoidCallback onPurchase;
  final bool isLoading;

  const AllPlansSheet({
    super.key,
    required this.packages,
    required this.selectedPackage,
    required this.onSelect,
    required this.onPurchase,
    required this.isLoading,
  });

  @override
  State<AllPlansSheet> createState() => _AllPlansSheetState();
}
class _AllPlansSheetState extends State<AllPlansSheet> {
  int _tabIndex = 0;
  late Package? _localSelected; // 👈 new — local copy, updates immediately

  String? _monthlyEquivalent(Package pkg) {
    if (pkg.packageType != PackageType.annual) return null;
    final annualPrice = pkg.storeProduct.price;
    final monthly = annualPrice / 12;
    final symbol = pkg.storeProduct.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${monthly.toStringAsFixed(2)}/month';
  }

  @override
  void initState() {
    super.initState();
    _localSelected = widget.selectedPackage;
    _tabIndex = 0; // 👈 always default to One-Time, regardless of incoming selection
    _selectDefaultForTab(_tabIndex);
  }
  @override
  Widget build(BuildContext context) {
    final annual = widget.packages.where((p) => p.packageType == PackageType.annual).firstOrNull;
    final monthly = widget.packages.where((p) => p.packageType == PackageType.monthly).firstOrNull;
    final lifetime = widget.packages.where((p) => p.packageType == PackageType.lifetime).firstOrNull;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF16162A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1a0a3d), Color(0xFF16162a)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ClipRRect( // 👈 new — keeps the image's corners rounded to match the container
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Image.asset(
                    'assets/images/squareman.png',
                    fit: BoxFit.cover, // fills the whole 220-height area, cropping if needed
                    width: double.infinity,
                    height: 220,
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45), // 👈 was Colors.white.withValues(alpha: 0.15)
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E35),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _tabButton('One-Time', 0)), // 👈 was 'Subscriptions', now index 0
                        Expanded(child: _tabButton('Subscriptions', 1)), //
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_tabIndex == 1) ...[
                    if (annual != null)
                      _PlanOptionRow(
                        label: 'Annual',
                        priceLine: '${annual.storeProduct.priceString}/year',
                        badge: 'Free Trial',
                        discountBadge: '-58%', // 👈 new
                        subLine: 'One Week Free, then ${_monthlyEquivalent(annual)}',
                        isSelected: _localSelected?.identifier == annual.identifier, // 👈 local
                        onTap: () => setState(() => _localSelected = annual), // 👈 local setState
                      ),
                    if (annual != null && monthly != null)
                      const SizedBox(height: 12),
                    if (monthly != null)
                      _PlanOptionRow(
                        label: 'Monthly',
                        priceLine: '${monthly.storeProduct.priceString}/month',
                        badge: 'Free Trial',
                        subLine: 'One Week Free, then ${monthly.storeProduct.priceString}/month.',
                        isSelected: _localSelected?.identifier == monthly.identifier,
                        onTap: () => setState(() => _localSelected = monthly),
                      ),
                  ],

                  if (_tabIndex == 0) ...[
                    if (lifetime != null)
                      _PlanOptionRow(
                        label: 'Lifetime Unlock',
                        priceLine: '',
                        subLine: 'One-time payment of ${lifetime.storeProduct.priceString}.',
                        isSelected: _localSelected?.identifier == lifetime.identifier,
                        onTap: () => setState(() => _localSelected = lifetime),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Lifetime plan not available',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isLoading || _localSelected == null
                    ? null
                    : () {
                  widget.onSelect(_localSelected!); // 👈 sync final choice back to parent
                  Navigator.pop(context);
                  widget.onPurchase();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEDB82A),
                  foregroundColor: const Color(0xFF1A1208),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  elevation: 0,
                  textStyle: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                child: Text(
                  _tabIndex == 0
                      ? 'Get Lifetime Access'
                      : 'Redeem Your Free Week',
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _tabIndex = index;
        _selectDefaultForTab(index); // 👈 new
      }),      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEDB82A) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: isActive ? const Color(0xFF1A1208) : Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
// 👇 new — ensures something is always selected within the tab you just switched to
  void _selectDefaultForTab(int tabIndex) {
    final annual = widget.packages.where((p) => p.packageType == PackageType.annual).firstOrNull;
    final monthly = widget.packages.where((p) => p.packageType == PackageType.monthly).firstOrNull;
    final lifetime = widget.packages.where((p) => p.packageType == PackageType.lifetime).firstOrNull;

    if (tabIndex == 1) {
      // Subscriptions
      final isAlreadyValid = _localSelected?.packageType == PackageType.annual ||
          _localSelected?.packageType == PackageType.monthly;
      if (!isAlreadyValid) {
        _localSelected = annual ?? monthly;
      }
    } else {
      // One-Time
      if (_localSelected?.packageType != PackageType.lifetime) {
        _localSelected = lifetime;
      }
    }
  }


}

class _PlanOptionRow extends StatelessWidget {
  final String label;
  final String priceLine;
  final String subLine;
  final String? badge;
  final String? discountBadge; // 👈 new
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanOptionRow({
    required this.label,
    required this.priceLine,
    required this.subLine,
    this.badge,
    this.discountBadge, // 👈 new
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFEDB82A) : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFEDB82A) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFEDB82A) : Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Color(0xFF1A1208), size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (discountBadge != null) ...[ // 👈 new — sits right next to the label
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDB82A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEDB82A).withValues(alpha: 0.4), width: 0.5),
                          ),
                          child: Text(
                            discountBadge!,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFEDB82A),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (priceLine.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      priceLine,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    subLine,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDB82A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1A1208),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}