import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/theme/app_colors.dart';

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
      isDismissible: false,
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
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: AppColors.backgroundSubtle(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, color: AppColors.textSecondary(context), size: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Not a fan of subscriptions?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary(context),
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
                    color: AppColors.textSecondary(context),
                    fontSize: 15,
                  ),
                ),
                TextSpan(
                  text: 'one-time payment',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.accent(context),
                  ),
                ),
                TextSpan(
                  text: ' plan instead.',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary(context),
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
              color: AppColors.background(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent(context).withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lifetime Unlock',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row( // 👈 new — struck-through + new price
                  children: [
                    Text(
                      '\$59.99',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary(context),
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lifetimePackage.storeProduct.priceString,
                      style: GoogleFonts.poppins(
                        color: AppColors.accent(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, color: AppColors.accent(context), size: 16),
              const SizedBox(width: 6),
              Text(
                'Pay once, own it forever.',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary(context),
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
                backgroundColor: AppColors.accent(context),
                foregroundColor: AppColors.accentText(context),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: const StadiumBorder(),
                elevation: 0,
                textStyle: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              child: const Text('Start Today'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: onDecline,
              child: Text(
                'Not now, thanks',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}