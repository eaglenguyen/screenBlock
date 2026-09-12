import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../paywall/feature_paywall_screen.dart';
import '../../../providers/premium_provider.dart';
import '../../schedule/widgets/hold_to_confirm.dart';

const _pastelYellow = Color(0xFFFFE4A3);
const _pastelYellowText = Color(0xFF6B5417);
const _proOrange = Color(0xFFF2A340);

class BreakSheet extends ConsumerStatefulWidget {
  const BreakSheet({
    super.key,
    required this.onStartBreak,
  });

  final ValueChanged<int> onStartBreak;

  @override
  ConsumerState<BreakSheet> createState() => _BreakSheetState();
}

class _BreakSheetState extends ConsumerState<BreakSheet> {
  int _selectedMinutes = 5;

  static const _freeLimitMinutes = 10;

  bool get _isOverFreeLimit => _selectedMinutes > _freeLimitMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(context),
          const SizedBox(height: 20),
          const Text('☕️', style: TextStyle(fontSize: 36)), // 👈 new — matches the emoji convention
          const SizedBox(height: 8),
          _buildTitle(),
          const SizedBox(height: 8),
          _buildValue(context),
          const SizedBox(height: 16),
          _buildSlider(context),
          if (_isOverFreeLimit) ...[
            const SizedBox(height: 8),
            _buildProNotice(context),
          ],
          const SizedBox(height: 24), // 👈 was 20
          _buildStartButton(context),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border(context),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'How long?',
      style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w900), // 👈 was headlineSmall, no weight override
      textAlign: TextAlign.center,
    );
  }

  Widget _buildValue(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$_selectedMinutes minutes',
          style: AppTextStyles.headlineMedium.copyWith(
            color: _isOverFreeLimit ? _proOrange : _pastelYellowText, // 👈 was AppColors.warning(context)
            fontWeight: FontWeight.w800, // 👈 new
          ),
          textAlign: TextAlign.center,
        ),
        if (_isOverFreeLimit) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _proOrange,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              'PRO',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSlider(BuildContext context) {
    final trackColor = _isOverFreeLimit ? _proOrange : _pastelYellow; // 👈 was AppColors.warning(context)
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: trackColor,
        inactiveTrackColor: AppColors.backgroundSubtle(context),
        thumbColor: trackColor,
        overlayColor: trackColor.withValues(alpha: 0.2),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12,
        ),
        trackHeight: 6, // 👈 was 4 — chunkier, matches the pill-bar convention
      ),
      child: Slider(
        value: _selectedMinutes.toDouble(),
        min: 3,
        max: 30,
        divisions: 27,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() => _selectedMinutes = value.round());
        },
      ),
    );
  }

  Widget _buildProNotice(BuildContext context) {
    return Text(
      'Breaks over $_freeLimitMinutes min require Pro',
      style: AppTextStyles.bodyMedium.copyWith( // 👈 was bodySmall — bumped up
        color: AppColors.textSecondary(context),
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: HoldToConfirmButton(
        color: _pastelYellow, // 👈 was AppColors.warning(context)
        fillColor: const Color(0xFFF7C948), // 👈 was AppColors.warningDark(context) — a slightly richer yellow for the fill/progress state
        textColor: _pastelYellowText, // 👈 was AppColors.warningLight(context)
        onConfirmed: () {
          if (_isOverFreeLimit) {
            final isPremium = ref.read(isPremiumProvider);
            if (!isPremium) {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useRootNavigator: true,
                builder: (_) => const FeaturePaywallScreen(source: 'break_over_10min'),
              );
              return;
            }
          }
          widget.onStartBreak(_selectedMinutes);
          Navigator.pop(context);
        },
      ),
    );
  }
}