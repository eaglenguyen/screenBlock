import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lipped_card.dart';
import '../home_state.dart';

const _pastelYellow = Color(0xFFFFE4A3);
const _pastelYellowText = Color(0xFF6B5417);

class ActiveBlockingCard extends StatelessWidget {
  final HomeState state;
  final VoidCallback onTakeBreak;
  final VoidCallback onGiveUp;
  final VoidCallback onEndBreak;
  final VoidCallback onBlockListTapped;
  final bool isPomodoroMode;
  final int pomodoroRound;
  final bool isPaused;
  final VoidCallback onPauseToggle;
  final VoidCallback onRestart;
  final VoidCallback onSkipRound;
  final bool isHardMode;

  const ActiveBlockingCard({
    super.key,
    required this.state,
    required this.onTakeBreak,
    required this.onGiveUp,
    required this.onEndBreak,
    required this.onBlockListTapped,
    required this.isPomodoroMode,
    this.pomodoroRound = 0,
    this.isPaused = false,
    required this.onPauseToggle,
    required this.onRestart,
    required this.onSkipRound,
    this.isHardMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return LippedCard( // 👈 was Container — now uses the shared bubbly-card offset-shadow treatment
      padding: const EdgeInsets.all(28), // 👈 was 20 — bigger overall
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8), // 👈 was 4 — a bit more room now that the close button is bigger
              _buildTimer(context),
              const SizedBox(height: 16), // 👈 was 12
              _buildXpBar(context),
              const SizedBox(height: 20), // 👈 was 16
              if (isPomodoroMode)
                _buildPomodoroControls(context)
              else ...[
                _buildTakeBreakButton(context),
                const SizedBox(height: 10),
              ],
            ],
          ),
          Positioned(
            top: 0,
            left: isPomodoroMode ? 0 : null,
            right: isPomodoroMode ? null : 0,
            child: Opacity(
              opacity: isHardMode ? 0.35 : 1.0,
              child: GestureDetector(
                onTap: isHardMode ? null : onGiveUp,
                child: Container(
                  width: 36, // 👈 was 32 — bigger
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSubtle(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border(context), width: 0.5),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20, // 👈 was 18
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ),
          ),
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
    final isOnBreak = state.phase == BlockingPhase.onBreak;
    final displayRound = isOnBreak
        ? pomodoroRound
        : pomodoroRound + 1;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundSubtle(context),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.border(context), width: 0.5),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        if (isPomodoroMode) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(4, (i) {
                final currentRoundInCycle = displayRound % 4 == 0 && displayRound > 0
                    ? 4
                    : (displayRound % 4);
                final completed = i < currentRoundInCycle;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? const Color(0xFFE74C3C)
                        : const Color(0xFFE74C3C).withValues(alpha: 0.2),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text(
                'Round $displayRound',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
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
            style: AppTextStyles.bodyMedium.copyWith( // 👈 was bodySmall — bumped up
              color: _pastelYellowText,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (isPaused)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Paused',
              style: AppTextStyles.bodyMedium.copyWith( // 👈 was bodySmall
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Text(
          '$h:$m:$s',
          style: TextStyle(
            fontSize: 56, // 👈 was 48 — bigger, more commanding
            fontWeight: FontWeight.w900,
            color: isPaused
                ? AppColors.textSecondary(context)
                : AppColors.textPrimary(context),
            letterSpacing: -1.5,
            fontFeatures: const [FontFeature.tabularFigures()],
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
    final xpSoFar = (elapsed / 60).floor() * 1;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.backgroundSubtle(context),
              valueColor: const AlwaysStoppedAnimation(_pastelYellow),
              minHeight: 10, // 👈 was 8 — chunkier
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '+$xpSoFar ⭐️',
          style: AppTextStyles.bodyLarge.copyWith( // 👈 was bodyMedium — bumped up
            color: _pastelYellowText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Future<int> getOpenAttemptCount() async {
    try {
      final count = await const MethodChannel('com.eagle.pausenow/ios_blocking')
          .invokeMethod<int>('getOpenAttemptCount');
      return count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildPomodoroControls(BuildContext context) {
    if (!isPaused) {
      return Opacity(
        opacity: isHardMode ? 0.35 : 1.0,
        child: SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: isHardMode ? null : onPauseToggle,
            icon: Icon(
              Icons.pause_rounded,
              color: AppColors.textPrimary(context),
              size: 22, // 👈 was 20
            ),
            label: Text(
              'Pause',
              style: AppTextStyles.labelLarge.copyWith( // 👈 was labelMedium
                color: AppColors.textPrimary(context),
                fontSize: 17, // 👈 was 15
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.backgroundSubtle(context),
              padding: const EdgeInsets.symmetric(vertical: 16), // 👈 was 14
              shape: const StadiumBorder(),
            ),
          ),
        ),
      );
    }
    return Opacity(
      opacity: isHardMode ? 0.35 : 1.0,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: isHardMode ? null : onPauseToggle,
              icon: Icon(
                Icons.play_arrow_rounded,
                color: _pastelYellowText,
                size: 22,
              ),
              label: Text(
                'Resume',
                style: AppTextStyles.labelLarge.copyWith(
                  color: _pastelYellowText,
                  fontSize: 17,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _pastelYellow.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: isHardMode ? null : onRestart,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textSecondary(context),
                    size: 20, // 👈 was 18
                  ),
                  label: Text(
                    'Restart',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary(context),
                      fontSize: 15, // 👈 was 14
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.backgroundSubtle(context),
                    padding: const EdgeInsets.symmetric(vertical: 14), // 👈 was 12
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: isHardMode ? null : onSkipRound,
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: AppColors.textSecondary(context),
                    size: 20,
                  ),
                  label: Text(
                    'Skip Round',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary(context),
                      fontSize: 15,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.backgroundSubtle(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTakeBreakButton(BuildContext context) {
    final isOnBreak = state.phase == BlockingPhase.onBreak;
    return Opacity(
      opacity: isHardMode ? 0.35 : 1.0,
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: isHardMode ? null : (isOnBreak ? onEndBreak : onTakeBreak),
          icon: Icon(
            isOnBreak ? Icons.stop : Icons.pause_rounded,
            color: isOnBreak
                ? _pastelYellowText
                : AppColors.textPrimary(context),
            size: 22, // 👈 was 20
          ),
          label: Text(
            isOnBreak ? 'End Break' : 'Take A Break',
            style: AppTextStyles.labelLarge.copyWith( // 👈 was labelMedium
              color: AppColors.textPrimary(context),
              fontSize: 19, // 👈 was 18
              fontWeight: FontWeight.w700, // 👈 new
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor:AppColors.backgroundSubtle(context),
            padding: const EdgeInsets.symmetric(vertical: 16), // 👈 was 14
            shape: const StadiumBorder(),
          ),
        ),
      ),
    );
  }
}