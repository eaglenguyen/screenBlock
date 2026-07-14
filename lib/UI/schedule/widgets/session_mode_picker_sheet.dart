import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SessionModePickerSheet extends StatefulWidget {
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
  State<SessionModePickerSheet> createState() => _SessionModePickerSheetState();
}

class _SessionModePickerSheetState extends State<SessionModePickerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardAnims;

  static const int _cardCount = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _cardAnims = List.generate(_cardCount, (i) {
      final start = (i * 0.3).clamp(0.0, 0.7); // 👈 stagger step per card
      final end = (start + 0.45).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    // 👇 wait for the modal's own entrance animation to finish first
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _controller.forward();
    });

    _controller.forward();
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
          offset: Offset(0, 30 * (1 - anim.value)), // 👈 slides up from below
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        mainAxisSize: MainAxisSize.min, // 👈 was crossAxisAlignment: CrossAxisAlignment.stretch
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
              const SizedBox(width: 10),
              Expanded(
                child: _animatedCard(
                  1,
                  _modeCard(
                    context,
                    title: 'Time Limit',
                    subtitle: 'Daily usage cap',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onTimeLimitTap();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
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

          const SizedBox(height: 60), // 👈 add this — adjust the number to taste

        ],
      ),
    );
  }

  Widget _modeCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required VoidCallback? onTap,
      }) {
    final isDisabled = onTap == null;

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundSubtle(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold(context).withValues(alpha: 0.8), // 👈 was AppColors.border(context)
              width: 1, // 👈 slightly thicker than the default 0.5, to make the gold actually read
            ),          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}