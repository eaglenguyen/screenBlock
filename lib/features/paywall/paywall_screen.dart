import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Paywall', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}