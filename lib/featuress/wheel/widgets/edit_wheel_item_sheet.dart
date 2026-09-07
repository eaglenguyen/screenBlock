// lib/featuress/wheel/widgets/edit_wheel_items_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/wheel_presets.dart';
import '../wheel_viewmodel.dart';

class EditWheelItemsSheet extends ConsumerStatefulWidget {
  const EditWheelItemsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const EditWheelItemsSheet(),
    );
  }

  @override
  ConsumerState<EditWheelItemsSheet> createState() => _EditWheelItemsSheetState();
}

class _EditWheelItemsSheetState extends ConsumerState<EditWheelItemsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(wheelViewModelProvider.notifier).addItem(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wheelViewModelProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),
          Text('Edit Wheel Items', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Add an item...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                    filled: true,
                    fillColor: AppColors.backgroundSubtle(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, color: AppColors.accentText(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.items.isEmpty)
            GestureDetector(
              onTap: () => ref.read(wheelViewModelProvider.notifier).addPresetList(WheelPresets.defaultList),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent(context).withValues(alpha: 0.3), width: 0.5),
                ),
                child: Center(
                  child: Text(
                    'Use suggested list',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent(context), fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          ...state.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundSubtle(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary(context))),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(wheelViewModelProvider.notifier).removeItem(item),
                    child: Icon(Icons.close_rounded, color: AppColors.textSecondary(context), size: 18),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}