import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class LastChanceOfferSheet extends StatelessWidget {
  final Package lifetimePackage;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const LastChanceOfferSheet({
    super.key,
    required this.lifetimePackage,
    required this.onAccept,
    required this.onDecline,
  });

  static Future<void> show(
      BuildContext context, {
        required Package lifetimePackage,
        required VoidCallback onAccept,
        required VoidCallback onDecline,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isDismissible: false, // 👈 force an explicit choice, not a tap-outside dismiss
      enableDrag: false,
      builder: (_) => LastChanceOfferSheet(
        lifetimePackage: lifetimePackage,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onDecline,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white54, size: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Not a fan of subscriptions?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'We get it. Try a ',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                ),
                TextSpan(
                  text: 'one-time payment',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFFEDB82A),
                  ),
                ),
                TextSpan(
                  text: ' plan instead.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDB82A).withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lifetime Unlock',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${lifetimePackage.storeProduct.priceString}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEDB82A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_rounded, color: Color(0xFFEDB82A), size: 16),
              const SizedBox(width: 6),
              Text(
                'Pay once, own it forever.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEDB82A),
                foregroundColor: const Color(0xFF1A1208),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: const StadiumBorder(),
                elevation: 0,
                textStyle: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              child: const Text('Begin your health journey'),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: GestureDetector(
              onTap: onDecline,
              child: Text(
                'Not now, thanks',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decorationColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}