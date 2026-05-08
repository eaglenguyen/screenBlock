// ── Today's focus card ───────────────────────────
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_state.dart';

class FocusStatsCard extends StatelessWidget {
  const FocusStatsCard({
    super.key,
    required this.state,
  });

  final HomeState state;

@override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.border,
        width: 0.5,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Text("Today's Focus",
              style: AppTextStyles.headlineSmall,
            ),
            const Spacer(),
            Text('Day 1',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _focusStat('0h', 'Saved',
              valueColor: AppColors.gold,
            ),
            const SizedBox(width: 8),
            _focusStat(
              '🔥 ${state.streak?.currentStreak ?? 0}',
              'Streak',
            ),
            const SizedBox(width: 8),
            _focusStat('0', 'Blocks'),
          ],
        ),
      ],
    ),
  );
}

Widget _focusStat(
    String value,
    String label, {
      Color? valueColor,
    }) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontSize: 18,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    ),
  );
}
}