import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Timer', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}