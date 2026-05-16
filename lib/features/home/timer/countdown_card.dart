import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CountdownCard extends StatelessWidget {
  const CountdownCard({
    super.key,
    required this.count,
    required this.onCancel,
  });

  final int count;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a2a4a),
            Color(0xFF16162a),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 24,
      ),
      child: Column(
        children: [
          Text(
            'Blocking apps in',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Text(
              '$count',
              key: ValueKey(count),
              style: const TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onCancel,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Cancel',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}