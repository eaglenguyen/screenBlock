import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const PurchaseSuccessScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.gold(context).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: AppColors.gold(context),
              size: 44,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Payment Successful',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary(context),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Enjoy Pause Now Pro.',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary(context),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold(context),
                foregroundColor: AppColors.goldText(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                elevation: 0,
                textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}