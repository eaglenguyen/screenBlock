import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../UI/schedule/widgets/session_card_shell.dart';
import '../../../UI/schedule/widgets/app_icon_stack.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/lock_app_config.dart';
import '../lock_app_viewmodel.dart';

class LockAppCard extends StatefulWidget {
  final LockAppConfig config;
  final VoidCallback onOptionsTap;
  final VoidCallback onUnlockTap;

  const LockAppCard({
    super.key,
    required this.config,
    required this.onOptionsTap,
    required this.onUnlockTap,
  });

  @override
  State<LockAppCard> createState() => _LockAppCardState();
}

class _LockAppCardState extends State<LockAppCard> {
  Timer? _tickTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _updateSecondsLeft();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateSecondsLeft());
  }

  @override
  void didUpdateWidget(LockAppCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSecondsLeft();
  }

  void _updateSecondsLeft() {
    final endsAt = widget.config.pauseEndsAt;
    if (endsAt == null || !widget.config.isPausing) {
      if (_secondsLeft != 0 && mounted) setState(() => _secondsLeft = 0);
      return;
    }
    final remaining = endsAt.difference(DateTime.now()).inSeconds.clamp(0, 999999);
    if (mounted) setState(() => _secondsLeft = remaining);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String get _formattedCountdown {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showEndEarlyConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End unlock early?',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'The app will be blocked. Any remaining time will be lost.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(lockAppViewModelProvider.notifier).endPauseEarly(widget.config.id, widget.config.packageName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: const Text('End Now'),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Keep going', style: TextStyle(color: AppColors.textSecondary(context))),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isExhausted = widget.config.isExhausted;
        final isPausing = widget.config.isPausing;

        return SessionCardShell(
          icon: AppIconStack(
            packageNames: [widget.config.packageName],
            iosStorageKey: 'lockApp_${widget.config.id}',
            refreshToken: widget.config.updatedAt.millisecondsSinceEpoch,
            size: 48,
          ),
          name: widget.config.appName,
          onOptionsTap: widget.onOptionsTap,
          bottomAction: isPausing
              ? GestureDetector(
            onTap: () => _showEndEarlyConfirm(context, ref),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 0.5),
              ),
              child: Center(
                child: Text(
                  _formattedCountdown,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )
              : SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isExhausted ? null : widget.onUnlockTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
                side: BorderSide(color: AppColors.border(context)),
                disabledForegroundColor: AppColors.textSecondary(context).withValues(alpha: 0.5),
              ),
              child: Text(
                'Unlock (${widget.config.remaining}/${widget.config.maxUnlocks})',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      },
    );
  }
}