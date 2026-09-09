import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/premium_provider.dart';
import '../../../paywall/feature_paywall_screen.dart';

class SessionModePickerSheet extends ConsumerStatefulWidget {
  final VoidCallback onScheduleTap;
  final VoidCallback onTimeLimitTap;
  final VoidCallback onLockAppTap;
  final bool hasTimeLimitConfig; // 👈 new
  final bool hasLockAppConfig; // 👈 new

  const SessionModePickerSheet({
    super.key,
    required this.onScheduleTap,
    required this.onTimeLimitTap,
    required this.onLockAppTap,
    this.hasTimeLimitConfig = false, // 👈 new
    this.hasLockAppConfig = false, // 👈 new
  });

  static void show(
      BuildContext context, {
        required VoidCallback onScheduleTap,
        required VoidCallback onTimeLimitTap,
        required VoidCallback onLockAppTap,
        bool hasTimeLimitConfig = false, // 👈 new
        bool hasLockAppConfig = false, // 👈 new
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => SessionModePickerSheet(
        onScheduleTap: onScheduleTap,
        onTimeLimitTap: onTimeLimitTap,
        onLockAppTap: onLockAppTap,
        hasTimeLimitConfig: hasTimeLimitConfig, // 👈 new
        hasLockAppConfig: hasLockAppConfig, // 👈 new
      ),
    );
  }

  @override
  ConsumerState<SessionModePickerSheet> createState() => _SessionModePickerSheetState();
}

class _SessionModePickerSheetState extends ConsumerState<SessionModePickerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardAnims;
  late Animation<double> _dividerAnim;
  static const int _cardCount = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _cardAnims = List.generate(_cardCount, (i) {
      final start = (i * 0.3).clamp(0.0, 0.7);
      final end = (start + 0.45).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _dividerAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedCard(int index, Widget child) {
    final anim = _cardAnims[index];
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  Widget _animatedDivider(Widget child) {
    return AnimatedBuilder(
      animation: _dividerAnim,
      builder: (_, c) => Opacity(
        opacity: _dividerAnim.value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - _dividerAnim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 20,
        right: 20,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Create a Session',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose how you want to block apps',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _animatedCard(
                  0,
                  _modeCard(
                    context,
                    title: 'Schedule',
                    subtitle: 'Specific days & times',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onScheduleTap();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _animatedDivider(
                Container(
                  width: 1,
                  height: 88,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: AppColors.accent(context).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded( // 👈 Lock an App now goes second (index 1)
                child: _animatedCard(
                  1,
                  _modeCard(
                    context,
                    title: 'Lock an App',
                    subtitle: widget.hasLockAppConfig ? 'Already created' : 'Limit unlocks per day',
                    isLocked: !isPremium || widget.hasLockAppConfig,
                    isAlreadyCreated: widget.hasLockAppConfig,
                    lockMessage: widget.hasLockAppConfig ? 'Session already created' : 'Upgrade to unlock',
                    onTap: widget.hasLockAppConfig
                        ? null
                        : isPremium
                        ? () {
                      Navigator.pop(context);
                      widget.onLockAppTap();
                    }
                        : () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        useRootNavigator: true,
                        builder: (_) => const FeaturePaywallScreen(source: 'lock_app_mode_card'),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded( // 👈 Time Limit now goes third (index 2)
                child: _animatedCard(
                  2,
                  _modeCard(
                    context,
                    title: 'Time Limit',
                    subtitle: widget.hasTimeLimitConfig ? 'Already created' : 'Daily usage cap',
                    isLocked: !isPremium || widget.hasTimeLimitConfig,
                    isAlreadyCreated: widget.hasTimeLimitConfig,
                    lockMessage: widget.hasTimeLimitConfig ? 'Session already created' : 'Upgrade to unlock',
                    showBetaFlair: Platform.isIOS && !widget.hasTimeLimitConfig,
                    onTap: widget.hasTimeLimitConfig
                        ? null
                        : isPremium
                        ? () {
                      Navigator.pop(context);
                      widget.onTimeLimitTap();
                    }
                        : () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        useRootNavigator: true,
                        builder: (_) => const FeaturePaywallScreen(source: 'time_limit_mode_card'),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _modeCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required VoidCallback? onTap,
        bool isLocked = false,
        bool isAlreadyCreated = false, // 👈 new
        bool showBetaFlair = false,
        String lockMessage = 'Upgrade to unlock', // 👈 new
      }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Opacity(
            opacity: (isDisabled || isLocked) ? 0.4 : 1.0,
            child: Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent(context).withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showBetaFlair && !isLocked)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 0.5),
                ),
                child: Text(
                  'BETA',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isAlreadyCreated) // 👈 new — hide the lock icon for this case
                        Icon(
                          Icons.lock_rounded,
                          color: AppColors.accent(context),
                          size: 16,
                        ),
                      if (!isAlreadyCreated) const SizedBox(height: 4), // 👈 new — keep spacing only when icon present
                      Text(
                        lockMessage,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}