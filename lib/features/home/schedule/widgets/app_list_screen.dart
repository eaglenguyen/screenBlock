import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../appPicker/app_picker_screen.dart';
import '../../../appPicker/app_picker_state.dart';

class AppListScreen extends ConsumerWidget {
  const AppListScreen({
    super.key,
    required this.isBlockList,
    required this.apps,
    required this.onAppsChanged,
  });

  final bool isBlockList;
  final List<String> apps;
  final ValueChanged<List<String>> onAppsChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = isBlockList ? 'Blocked Apps' : 'Allowed Apps';
    final subtitle = isBlockList
        ? 'These apps will remain blocked during your sessions'
        : 'These apps will remain unblocked during your sessions';
    final emptyLabel = isBlockList
        ? 'Add apps to block'
        : 'Add apps to allow';
    final counterLabel = isBlockList
        ? 'Apps Blocked'
        : 'Apps Allowed';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, title, subtitle),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16, 16, 16, 100,
              ),
              child: Column(
                children: [
                  _buildCounter(
                    context,
                    counterLabel,
                    apps.length,
                    isBlockList,
                  ),
                  const SizedBox(height: 12),
                  if (apps.isNotEmpty)
                    ...apps.map(
                          (pkg) => _buildAppRow(pkg),
                    ),
                  _buildEmptyRow(emptyLabel, context, isBlockList),
                ],
              ),
            ),
          ),
          _buildDoneButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      String title,
      String subtitle,
      ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Column(
        children: [
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(
      BuildContext context,
      String label,
      int count,
      bool isBlock,
      ) {
    return Row(
      children: [
        const Text('📱', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count/50',
          style: AppTextStyles.bodyMedium,
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _openPicker(context, isBlock),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              'ADD / REMOVE',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.goldText,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppRow(String packageName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.backgroundSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.apps_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              packageName,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRow(
      String label,
      BuildContext context,
      bool isBlock,
      ) {
    return GestureDetector(
      onTap: () => _openPicker(context, isBlock),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.faint,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.goldText,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
            textStyle: AppTextStyles.labelLarge,
          ),
          child: const Text('Done'),
        ),
      ),
    );
  }

  void _openPicker(BuildContext context, bool isBlock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => AppPickerScreen(
        mode: isBlock
            ? AppPickerMode.blockList
            : AppPickerMode.allowList,
        preSelected: apps,
        onSave: onAppsChanged,
      ),
    );
  }
}