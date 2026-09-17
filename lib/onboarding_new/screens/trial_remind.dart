import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';




// ── Trial Reminder Screen ─────────────────────────────
// lib/onboarding_new/screens/trial_reminder_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../widget/continue_button.dart';

class OnboardingTrialReminderScreen extends StatefulWidget {
  final VoidCallback onNext;
  const OnboardingTrialReminderScreen({
    super.key,
    required this.onNext,
  });

  @override
  State<OnboardingTrialReminderScreen> createState() => _OnboardingTrialReminderScreenState();
}

class _OnboardingTrialReminderScreenState extends State<OnboardingTrialReminderScreen> {
  Future<void> _requestNotificationAndContinue() async {
    HapticFeedback.lightImpact();
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      if (Platform.isIOS) {
        final iosPlugin = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
      } else {
        final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('❌ notification permission error: $e');
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED), // 👈 was Color(0xFF16162A)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              Text(
                "We'll send you\na reminder before your\nfree trial ends",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4A3728), // 👈 was Colors.white
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.3,
                ),
              ),
              Center(
                child: Lottie.asset(
                  'assets/lottie/bell.json',
                  width: 180,
                  height: 180,
                ),
              ),
              const Spacer(flex: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, color: Color(0xFF2D7A54), size: 14), // 👈 was Color(0xFFEDB82A)
                  const SizedBox(width: 4),
                  Text(
                    'No Payment Due Now',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB08A5A), // 👈 was Colors.white.withValues(alpha: 0.6)
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OnboardingContinueButton( // 👈 was ElevatedButton — now matches your shared flow button
                label: 'Continue for FREE',
                onTap: _requestNotificationAndContinue,
              ),
              const SizedBox(height: 8),
              Text(
                '7 days free, then \$19.99/year (\$1.67/month)',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB08A5A).withValues(alpha: 0.8), // 👈 was Colors.white.withValues(alpha: 0.3)
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}