import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_state.dart';

class ActiveBlockingCard extends StatelessWidget {


  final HomeState state;
  final VoidCallback onTakeBreak;
  final VoidCallback onGiveUp;
  final VoidCallback onEndBreak;
  final VoidCallback onBlockListTapped; // 👈 add


  const ActiveBlockingCard({
    super.key,
    required this.state,
    required this.onTakeBreak,
    required this.onGiveUp,
    required this.onEndBreak, // 👈 add
    required this.onBlockListTapped, // 👈 add


  });


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _buildSessionIcon(),
          const SizedBox(height: 10),
          _buildSessionName(),
          const SizedBox(height: 12),
          _buildBlockListPill(),
          const SizedBox(height: 20),
          _buildTimer(),
          const SizedBox(height: 12),
          _buildXpBar(),
          const SizedBox(height: 16),
          _buildTakeBreakButton(),
          const SizedBox(height: 10),
          _buildGiveUpButton(),
        ],
      ),
    );
  }

  Widget _buildSessionIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a3a6a), Color(0xFF2a5aa0)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.shield_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildSessionName() {
    return Text(
      'Focus Session',
      style: AppTextStyles.headlineSmall,
    );
  }

  Widget _buildBlockListPill() {
    final label = state.blockingType ==
        'specific_apps'
        ? 'Specific Apps'
        : 'All Apps';

    return GestureDetector(
      onTap: onBlockListTapped, // 👈 add
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.apps_rounded,
              color: AppColors.textSecondary,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final isOnBreak = state.phase == BlockingPhase.onBreak;
    final seconds = isOnBreak
        ? state.breakRemainingSeconds
        : state.remainingSeconds;

    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60)
        .toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        if (isOnBreak)
          Text(
            'Break',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gold,
            ),
          ),
        Text(
          '$h:$m:$s',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildXpBar() {
    final totalSeconds = state.selectedMinutes * 60;
    final elapsed = totalSeconds - state.remainingSeconds;
    final progress = totalSeconds > 0
        ? (elapsed / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.backgroundSubtle,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.gold,
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '⚡ +10 XP',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTakeBreakButton() {
    final isOnBreak = state.phase == BlockingPhase.onBreak;

    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: isOnBreak ? onEndBreak : onTakeBreak,
        icon: Icon(
          isOnBreak
              ? null
              : Icons.pause_rounded,
          color: isOnBreak
              ? AppColors.gold
              : AppColors.textPrimary,
          size: 20,
        ),
        label: Text(
          isOnBreak ? 'End Break Now' : 'Take A Break',
          style: AppTextStyles.labelMedium.copyWith(
            color: isOnBreak
                ? AppColors.gold
                : AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.backgroundSubtle,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _buildGiveUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onGiveUp,
        icon: const Icon(
          Icons.stop_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: const Text('Give Up'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
    );
  }
}