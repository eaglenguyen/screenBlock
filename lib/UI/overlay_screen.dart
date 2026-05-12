import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  static const _channel = MethodChannel(
    'com.example.screenblock/block',
  );

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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: AppColors.gold,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Time's up",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "You've reached your limit\nfor this app today.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _blockForDay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDB82A),
                    foregroundColor: const Color(0xFF1A1208),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _returnToApp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    side: const BorderSide(
                      color: Color(0xFF2A2A48),
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
    _channel.invokeMethod('dismissBlockScreen');
  }

  void _returnToApp() {
    _channel.invokeMethod('dismissBlockScreen');
  }
}