import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackground(),
          _buildBadges(),
          _buildMascot(),
          _buildBottomContent(context),
        ],
      ),
    );
  }

  // ── Background ───────────────────────────────────
  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _SplashBackgroundPainter(),
      ),
    );
  }

  // ── Social proof badges ──────────────────────────
  Widget _buildBadges() {
    return Positioned(
      top: 64,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _badge('4.8', 'App Store'),
          Container(
            width: 1,
            height: 36,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _badge('300K', 'Downloads'),
        ],
      ),
    );
  }

  Widget _badge(String value, String label) {
    return Column(
      children: [
        Text(value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.gold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.tag),
      ],
    );
  }

  // ── Lottie mascot ────────────────────────────────
  Widget _buildMascot() {
    return Positioned(
      top: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Lottie.asset(
          'assets/lottie/cat.json',
          controller: _lottieController,
          width: 300,
          height: 300,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            _lottieController
              ..duration = composition.duration
              ..repeat(); // loops the idle animation forever
          },
        ),
      ),
    );
  }

  // ── Bottom content ───────────────────────────────
  Widget _buildBottomContent(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.95),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ScreenBlocker',
              style: AppTextStyles.headlineLarge.copyWith(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              'Take back your screen time',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // will navigate to onboarding later
                // context.go('/onboarding');
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Background painter ─────────────────────────────
class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // dark sky — already handled by scaffold bg

    // gold grass at bottom
    final grassPaint = Paint()..color = const Color(0xFFEDB82A);
    final grassPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.62,
        size.width, size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(grassPath, grassPaint);

    // darker gold under-layer for depth
    final darkGrassPaint = Paint()..color = const Color(0xFFC49420);
    final darkGrassPath = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.68,
        size.width, size.height * 0.76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(darkGrassPath, darkGrassPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}