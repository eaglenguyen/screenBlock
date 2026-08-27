import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final int pomodoroRound;
  final bool isPaused;
  final VoidCallback onPauseToggle;
  final VoidCallback onRestart;
  final VoidCallback onSkipRound;
  final bool isHardMode; // 👈 new

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
    this.isHardMode = false, // 👈 new
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
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 4),
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
              if (isPomodoroMode)
                _buildPomodoroControls(context)
              else ...[
                _buildTakeBreakButton(context),
                const SizedBox(height: 10),
              ],
            ],
          ),
          // 👇 close icon — grayed out and inert when Hard Mode is active
          Positioned(
            top: 0,
            left: isPomodoroMode ? 0 : null,
            right: isPomodoroMode ? null : 0,
            child: Opacity(
              opacity: isHardMode ? 0.35 : 1.0, // 👈 new
              child: GestureDetector(
                onTap: isHardMode ? null : onGiveUp, // 👈 new — no-op when locked
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSubtle(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border(context), width: 0.5),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
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
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gold(context),
            ),
          ),
        if (isPaused)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Paused',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Text(
          '$h:$m:$s',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: isPaused
                ? AppColors.textSecondary(context)
                : AppColors.textPrimary(context),
            letterSpacing: -1,
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
      return Opacity( // 👈 new
        opacity: isHardMode ? 0.35 : 1.0,
        child: SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: isHardMode ? null : onPauseToggle, // 👈 new
            icon: Icon(
              Icons.pause_rounded,
              color: AppColors.textPrimary(context),
              size: 20,
            ),
            label: Text(
              'Pause',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textPrimary(context),
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
      );
    }
    // ── paused — Resume, then Restart + Skip Round side by side ──
    // note: reaching this state at all under Hard Mode shouldn't be possible
    // (since pausing is itself locked above), but the same guards are applied
    // here defensively in case of a pre-existing pause when Hard Mode gets enabled
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
                color: AppColors.gold(context),
                size: 20,
              ),
              label: Text(
                'Resume',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.gold(context),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: isHardMode ? null : onRestart,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textSecondary(context),
                    size: 18,
                  ),
                  label: Text(
                    'Restart',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.backgroundSubtle(context),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                    size: 18,
                  ),
                  label: Text(
                    'Skip Round',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.backgroundSubtle(context),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
    return Opacity( // 👈 new
      opacity: isHardMode ? 0.35 : 1.0,
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: isHardMode ? null : (isOnBreak ? onEndBreak : onTakeBreak), // 👈 new
          icon: Icon(
            isOnBreak ? null : Icons.pause_rounded,
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
      ),
    );
  }
}