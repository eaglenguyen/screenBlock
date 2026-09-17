// lib/onboarding_new/screens/loading_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingLoadingProfileScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingLoadingProfileScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<OnboardingLoadingProfileScreen> createState() => _OnboardingLoadingProfileScreenState();
}

class _OnboardingLoadingProfileScreenState extends State<OnboardingLoadingProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward().whenComplete(() {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) widget.onContinue();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: Center( // 👈 new — wraps everything, forces true centering regardless of parent constraints
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 👈 new — Column only takes the space its children need
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, child) {
                    return SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand( // 👈 new — forces the indicator to fill the 72x72 box again
                            child: CircularProgressIndicator(
                              value: _progress.value,
                              strokeWidth: 7,
                              backgroundColor: const Color(0xFFF0E6D8),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7DD3B0)),
                            ),
                          ),
                          Text(
                            '${(_progress.value * 100).round()}%',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF4A3728),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'Analyzing and calculating\nyour answers...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4A3728),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}