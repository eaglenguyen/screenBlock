import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/premium_provider.dart';
import '../../../paywall/feature_paywall_screen.dart';

class SessionModePickerSheet extends ConsumerStatefulWidget { // 👈 needs to become Consumer to read premium status
  final VoidCallback onScheduleTap;
  final VoidCallback onTimeLimitTap;

  const SessionModePickerSheet({
    super.key,
    required this.onScheduleTap,
    required this.onTimeLimitTap,
  });

  static void show(
      BuildContext context, {
        required VoidCallback onScheduleTap,
        required VoidCallback onTimeLimitTap,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => SessionModePickerSheet(
        onScheduleTap: onScheduleTap,
        onTimeLimitTap: onTimeLimitTap,
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
    final isPremium = ref.watch(isPremiumProvider); // 👈 new

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
                  color: AppColors.gold(context).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _animatedCard(
                  1,
                  _modeCard(
                    context,
                    title: 'Time Limit',
                    subtitle: 'Daily usage cap',
                    isLocked: !isPremium, // 👈 new
                    onTap: isPremium
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
              const SizedBox(width: 8),
              Expanded(
                child: _animatedCard(
                  2,
                  _modeCard(
                    context,
                    title: 'Open Limit',
                    subtitle: 'Coming soon',
                    onTap: null,
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
        bool isLocked = false, // 👈 new — distinct from "disabled" (Open Limit)
      }) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // dimmed card content — same treatment whether disabled or locked
          Opacity(
            opacity: (isDisabled || isLocked) ? 0.4 : 1.0,
            child: Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold(context).withValues(alpha: 0.8),
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

          // 👇 lock overlay — only for isLocked (premium-gated), not for isDisabled (Open Limit "coming soon")
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16), // 👈 adjust this to push content down
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        color: AppColors.gold(context),
                        size: 16,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upgrade to unlock',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gold(context),
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