import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pausenow/features/lockapp/widget/single_app_picker_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/lock_app_config.dart';
import '../../../UI/home/widgets/app_list_sheet.dart';
import '../lock_app_viewmodel.dart';

class LockAppSheet extends ConsumerStatefulWidget {
  final LockAppConfig? existingConfig;

  const LockAppSheet({super.key, this.existingConfig});

  @override
  ConsumerState<LockAppSheet> createState() => _LockAppSheetState();
}

class _LockAppSheetState extends ConsumerState<LockAppSheet> {
  String? _packageName;
  String? _appName;
  int _maxUnlocks = 3;

  bool get isEditing => widget.existingConfig != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingConfig;
    _packageName = c?.packageName;
    _appName = c?.appName;
    _maxUnlocks = c?.maxUnlocks ?? 3;
  }
  void _openAppPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => SingleAppPickerSheet(
        onSelected: (packageName, appName) {
          setState(() {
            _packageName = packageName;
            _appName = appName;
          });
        },
      ),
    );
  }

  int get _dailyTotalMinutes => _maxUnlocks * 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isEditing)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSubtle(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, color: AppColors.textSecondary(context), size: 16),
                  ),
                )
              else
                const SizedBox(width: 32),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isEditing)
                GestureDetector(
                  onTap: _packageName == null ? null : _save,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, color: AppColors.accentText(context), size: 18),
                  ),
                )
              else
                const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 20),
          Image.asset('assets/icons/mascot_face.png', height: 56),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _openAppPicker,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Use ', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary(context))),
                      Text(
                        _appName ?? 'an app',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.unfold_more_rounded, size: 16, color: AppColors.textSecondary(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepperButton(
                      icon: Icons.remove_rounded,
                      onTap: _maxUnlocks > 1
                          ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _maxUnlocks--);
                      }
                          : null,
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        '$_maxUnlocks times',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _stepperButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _maxUnlocks++);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'max. per day',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                ),
                const SizedBox(height: 20),
                Text(
                  'For 5min each time',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '= ${_dailyTotalMinutes}min/day',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accent(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!isEditing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _packageName == null ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.backgroundCard(context),
                  foregroundColor: AppColors.textPrimary(context),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  disabledBackgroundColor: AppColors.backgroundCard(context).withValues(alpha: 0.5),
                  textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 17),
                ),
                child: const Text('+ Add'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _delete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error(context).withValues(alpha: 0.15),
                  foregroundColor: AppColors.error(context),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 17),
                ),
                child: const Text('Delete'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.backgroundSubtle(context).withValues(alpha: 0.5)
              : AppColors.backgroundSubtle(context),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary(context), size: 18),
      ),
    );
  }

  Future<void> _save() async {
    if (_packageName == null || _appName == null) return;
    await ref.read(lockAppViewModelProvider.notifier).saveConfig(
      existingId: widget.existingConfig?.id,
      name: _appName!,
      packageName: _packageName!,
      appName: _appName!,
      maxUnlocks: _maxUnlocks,
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.existingConfig == null) return;
    await ref.read(lockAppViewModelProvider.notifier).deleteConfig(widget.existingConfig!.id);
    if (mounted) Navigator.pop(context);
  }
}