import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hivebox_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../onboarding/onboarding_viewmodel.dart';

class SettingsProfileCard extends ConsumerWidget {
  const SettingsProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(onboardingViewModelProvider).userName ?? '';
    final displayName = name.isEmpty ? 'You' : name;
    final initial = displayName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Row(
        children: [
          // avatar with initial
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.gold(context),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.goldText(context),
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.labelMedium.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'Account Holder',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),

          // edit button
          GestureDetector(
            onTap: () => _showEditNameDialog(context, ref, name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(context), width: 0.5),
              ),
              child: Text(
                'Change name',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gold(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.backgroundCard(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.border(context),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit your name',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundSubtle(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context), width: 0.5),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: '',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _saveName(ctx, ref, controller.text),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary(context),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const StadiumBorder(),
                        side: BorderSide(color: AppColors.border(context)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveName(ctx, ref, controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold(context),
                        foregroundColor: AppColors.goldText(context),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveName(BuildContext ctx, WidgetRef ref, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.lightImpact();

    // update viewmodel
    ref.read(onboardingViewModelProvider.notifier).setUserName(trimmed);

    // persist to Hive
    final box = Hive.box(HiveBoxNames.settings);
    box.put('userName', trimmed);

    Navigator.pop(ctx);
  }
}