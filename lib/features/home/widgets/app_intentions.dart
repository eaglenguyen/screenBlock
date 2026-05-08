
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/timer_config.dart';


class AppIntentionsCard extends StatelessWidget {
  const AppIntentionsCard({
    super.key,
    required this.trackedApps,
    required this.onAddApp,
    required this.onRefresh,
  });

  final List<TimerConfig> trackedApps;
  final VoidCallback onAddApp;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(18),
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
        _buildIntentionsHeader(),
        const SizedBox(height: 4),
        if (trackedApps.isEmpty)
          _buildEmptyApps()
        else
          ...trackedApps.map(
                (app) => _buildAppItem(
              app.appName,
              app.packageName,
              app.limitMinutes,
            ),
          ),
        const SizedBox(height: 8),
        _buildAddIntentionRow(),
      ],
    ),
  );
}

Widget _buildIntentionsHeader() {
  return Row(
    children: [
      Text('App Intentions',
        style: AppTextStyles.headlineSmall,
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: onRefresh,
        child: const Icon(
          Icons.refresh_rounded,
          color: AppColors.textSecondary,
          size: 16,
        ),
      ),
      const Spacer(),
      GestureDetector(
        onTap: onAddApp,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: AppColors.goldText,
            size: 16,
          ),
        ),
      ),
    ],
  );
}

Widget _buildAppItem(
    String name,
    String packageName,
    int limitMinutes,
    ) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(
      horizontal: 12, vertical: 10,
    ),
    decoration: BoxDecoration(
      color: AppColors.backgroundSubtle,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.border,
        width: 0.5,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.apps_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                style: AppTextStyles.labelMedium,
              ),
              Text('0/$limitMinutes min used',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
        Text('${limitMinutes}m limit',
          style: AppTextStyles.bodySmall,
        ),
      ],
    ),
  );
}

Widget _buildEmptyApps() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      'No apps tracked yet',
      style: AppTextStyles.bodyMedium,
      textAlign: TextAlign.center,
    ),
  );
}

Widget _buildAddIntentionRow() {
  return GestureDetector(
    onTap: onAddApp,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.faint,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add,
            color: AppColors.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text('Add App Intention',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
}