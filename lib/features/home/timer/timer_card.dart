// ── Timer card ───────────────────────────────────
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';


class TimerCard extends StatelessWidget {
  final VoidCallback onBlockNow;
  final ValueChanged<String> onSelectorTapped;
  final VoidCallback onBlockModeTapped;
  final String blockingType;
  final VoidCallback onTimerTapped;   // 👈 add
  final int selectedMinutes;          // 👈 add


  const TimerCard({
    super.key,
    required this.onBlockNow,
    required this.onSelectorTapped,
    required this.onBlockModeTapped,
    required this.blockingType,
    required this.onTimerTapped,    // 👈 add
    required this.selectedMinutes,  // 👈 add

  });




  @override
Widget build (BuildContext context){
  return Container(
    padding: const EdgeInsets.all(20),
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
        Text('Time Blocked Today',
          style: AppTextStyles.headlineSmall.copyWith(
            fontSize: 25,
          ),

        ),
        const SizedBox(height: 8),
        _buildRecordPill(),
        const SizedBox(height: 16),
        _buildTimerDisplay(),
        const SizedBox(height: 16),
        _buildSelectorRow(),
        const SizedBox(height: 14),
        _buildBlockNowButton(),
      ],
    ),
  );
}

Widget _buildRecordPill() {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14, vertical: 5,
    ),
    decoration: BoxDecoration(
      color: AppColors.backgroundSubtle,
      borderRadius: BorderRadius.circular(50),
    ),
    child: Text(
      'No record set yet',
      style: AppTextStyles.bodySmall.copyWith(
        fontSize: 15,

      ),
    ),
  );
}

Widget _buildTimerDisplay() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _timerBlock('00', 'Hours'),
      _timerColon(),
      _timerBlock('00', 'Minutes'),
      _timerColon(),
      _timerBlock('00', 'Seconds'),
    ],
  );
}

Widget _timerBlock(String value, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12, vertical: 10,
    ),
    decoration: BoxDecoration(
      color: AppColors.backgroundSubtle,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: AppColors.border,
        width: 0.5,
      ),
    ),
    child: Column(
      children: [
        Text(value,
          style: AppTextStyles.displayMedium.copyWith(
            fontSize: 62,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
          style: AppTextStyles.bodySmall,
        ),
      ],
    ),
  );
}

Widget _timerColon() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(':',
      style: AppTextStyles.displayMedium.copyWith(
        fontSize: 28,
        color: AppColors.border,
      ),
    ),
  );
}

Widget _buildSelectorRow() {
  final isAllApps = blockingType == AppConstants.blockingTypeAllApps;

  return Row(
    children: [
      Expanded(
        child: _selectorPill(
          icon: '🛡️',
          label: isAllApps ? 'All Apps' : 'Specific Apps',
          onTap: onBlockModeTapped,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _selectorPill(
          icon: '⏱',
          label: selectedMinutes < 60
              ? '${selectedMinutes}m'
              : '${selectedMinutes ~/ 60}h', // 👈 dynamic label
          iconColor: AppColors.gold,
          onTap: onTimerTapped, // 👈 was onSelectorTapped('time')
        ),
      ),
    ],
  );
}

Widget _selectorPill(
    {
      required String icon,
      required String label,
      required VoidCallback onTap,
      Color? iconColor,    }
    ) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(icon,
            style: TextStyle(
              fontSize: 14,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
              style: AppTextStyles.labelMedium,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ],
      ),
    ),
  );
}

Widget _buildBlockNowButton() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onBlockNow,
      icon: const Icon(
        Icons.play_arrow_rounded,
        color: AppColors.goldText,
        size: 30,
      ),
      label: const Text('Block Now'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.goldText,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.labelLarge.copyWith(
            fontSize: 25
        ),
      ),
    ),
  );
}
}