import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withOpacity(0.97),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: AppColors.gold,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),

              // headline
              Text(
                "Time's up",
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: 42,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // subtitle
              Text(
                "You've reached your limit\nfor this app today.",
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // block for day button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _blockForDay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldText,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Block for today',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // return to app button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _returnToApp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: const StadiumBorder(),
                    side: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  child: const Text(
                    'Return to app',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _blockForDay() {
    // send message to main isolate to block the app
    FlutterOverlayWindow.shareData('block_for_day');
    FlutterOverlayWindow.closeOverlay();
  }

  void _returnToApp() {
    FlutterOverlayWindow.closeOverlay();
  }
}