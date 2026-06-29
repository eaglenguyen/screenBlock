import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home_state.dart';

class ActiveBlockingCard extends StatelessWidget {


  final HomeState state;
  final VoidCallback onTakeBreak;
  final VoidCallback onGiveUp;
  final VoidCallback onEndBreak;
  final VoidCallback onBlockListTapped;
  final bool isPomodoroMode;



  const ActiveBlockingCard({
    super.key,
    required this.state,
    required this.onTakeBreak,
    required this.onGiveUp,
    required this.onEndBreak,
    required this.onBlockListTapped,
    required this.isPomodoroMode,



  });


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.gold(context).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _buildSessionIcon(),
          const SizedBox(height: 10),
          _buildSessionName(),
          const SizedBox(height: 12),
          _buildBlockListPill(context),
          const SizedBox(height: 20),
          _buildTimer(context),
          const SizedBox(height: 12),
          _buildXpBar(context),
          const SizedBox(height: 16),
          _buildTakeBreakButton(context),
          const SizedBox(height: 10),
          _buildGiveUpButton(context),
        ],
      ),
    );
  }

  Widget _buildSessionIcon() {
    if (isPomodoroMode) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFE74C3C).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: const Center(
          child: Text('🍅', style: TextStyle(fontSize: 28)),
        ),
      );
    }

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
      isPomodoroMode ? 'Pomodoro Session' : 'Manual Session',
      style: AppTextStyles.headlineSmall,
    );
  }
  Widget _buildBlockListPill(BuildContext context) {
    final label = state.blockingType == 'specific_apps'
        ? 'Specific Apps'
        : 'All Apps';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(BuildContext context) {
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
              color: AppColors.gold(context),
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

  Widget _buildXpBar(BuildContext context) {
    final totalSeconds = state.selectedMinutes * 60;
    final elapsed = totalSeconds - state.remainingSeconds;
    final progress = totalSeconds > 0
        ? (elapsed / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    // 👇 calculate XP earned so far (5 XP per minute elapsed)
    final xpSoFar = (elapsed / 60).floor() * 5;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.backgroundSubtle(context),
              valueColor: AlwaysStoppedAnimation(AppColors.gold(context)),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '+$xpSoFar ⭐️',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gold(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  Widget _buildTakeBreakButton(BuildContext context) {
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
              ? AppColors.gold(context)
              : AppColors.textPrimary(context),
          size: 20,
        ),
        label: Text(
          isOnBreak ? 'End Break Now' : 'Take A Break',
          style: AppTextStyles.labelMedium.copyWith(
            color: isOnBreak
                ? AppColors.gold(context)
                : AppColors.textPrimary(context),
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.backgroundSubtle(context),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _buildGiveUpButton(BuildContext context) {
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
          backgroundColor: AppColors.error(context),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
    );
  }
}