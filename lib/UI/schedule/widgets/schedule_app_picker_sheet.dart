import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../onboarding_new/widget/app_picker_ios.dart';
import '../../../paywall/feature_paywall_screen.dart';
import '../../../providers/premium_provider.dart';

class ScheduleAppsPickerScreen extends ConsumerStatefulWidget {
  final String scheduleId;
  final int initialCount;
  final ValueChanged<int> onSaved;

  const ScheduleAppsPickerScreen({
    super.key,
    required this.scheduleId,
    required this.initialCount,
    required this.onSaved,
  });

  @override
  ConsumerState<ScheduleAppsPickerScreen> createState() => _ScheduleAppsPickerScreenState();
}

class _ScheduleAppsPickerScreenState extends ConsumerState<ScheduleAppsPickerScreen> {
  late int _selectedCount = widget.initialCount;

  bool get _isPremium => ref.read(isPremiumProvider);
  bool get _isOverLimit => !_isPremium && _selectedCount > 3;
  bool get _canSave => _selectedCount == 0 || _isPremium || _selectedCount <= 3;

  void _handleSave() {
    if (!_canSave) return;
    widget.onSaved(_selectedCount);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSubtle(context),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.border(context), width: 0.5),
                    ),
                    child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context), fontWeight: FontWeight.w600)),
                  ),
                ),
                Expanded(
                  child: Text('Blocked Apps', textAlign: TextAlign.center, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context))),
                ),
                GestureDetector(
                  onTap: _canSave ? _handleSave : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _canSave ? AppColors.accent(context) : AppColors.accent(context).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text('Save', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentText(context), fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          if (_isOverLimit)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    useRootNavigator: true,
                    builder: (_) => const FeaturePaywallScreen(source: 'multiple_schedules'),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFE8703A), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Max 3 apps. Upgrade to Pro for more!',
                      style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFE8703A), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: EmbeddedAppPicker(
                  saveKey: 'schedule_${widget.scheduleId}_specific_apps', // 👈 matches showSchedulePicker's key format exactly
                  onCountChanged: (count) => setState(() => _selectedCount = count),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}