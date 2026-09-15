import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pausenow/features/lockapp/widget/single_app_picker_sheet.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/lipped_button.dart';
import '../../../core/theme/lipped_card.dart';
import '../../../data/models/lock_app_config.dart';
import '../../../domain/platform/ios_blocking_service.dart';
import '../../../providers/blocking_service_provider.dart';
import '../lock_app_viewmodel.dart';
import '../service/app_store_search_result.dart';
import 'app_store_search_sheet.dart';

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
  String? _pendingConfigId;
  String? _iconUrl;

  bool get isEditing => widget.existingConfig != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingConfig;
    _packageName = c?.packageName;
    _appName = c?.appName;
    _maxUnlocks = c?.maxUnlocks ?? 3;
    _pendingConfigId = c?.id;
    _iconUrl = c?.iconUrl;
  }

  Future<void> _openAppPicker() async {
    if (Platform.isIOS) {
      final service = ref.read(blockingServiceProvider) as IOSBlockingService;
      _pendingConfigId ??= widget.existingConfig?.id ?? const Uuid().v4();
      final count = await service.showLockAppPicker(configId: _pendingConfigId!);
      if (count != null && count > 0 && mounted) {
        final result = await showModalBottomSheet<AppStoreSearchResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useRootNavigator: true,
          builder: (_) => const AppStoreSearchSheet(),
        );
        if (result != null) {
          setState(() {
            _packageName = _pendingConfigId!;
            _appName = result.trackName;
            _iconUrl = result.artworkUrl;
          });
        }
      }
    } else {
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
                    width: 36, // 👈 was 32 — bigger
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSubtle(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, color: AppColors.textSecondary(context), size: 18), // 👈 was 16
                  ),
                )
              else
                const SizedBox(width: 36),
              Container(
                width: 40, // 👈 was 36
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
                    width: 36, // 👈 was 32
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, color: AppColors.accentText(context), size: 20), // 👈 was 18
                  ),
                )
              else
                const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 24),
          LippedCard( // 👈 was a plain Container
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20), // 👈 was 24 — roomier
            child: Column(
              children: [
                GestureDetector(
                  onTap: _openAppPicker,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Choose ', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary(context))),
                      Text(
                        _appName ?? 'an app',
                        style: AppTextStyles.headlineSmall.copyWith( // 👈 was bodyLarge — bigger
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w900, // 👈 was w800
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textSecondary(context)), // 👈 was 16
                    ],
                  ),
                ),
                const SizedBox(height: 24), // 👈 was 20
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
                        style: AppTextStyles.headlineSmall.copyWith( // 👈 was bodySmall — much bigger
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w900,
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
                const SizedBox(height: 6),
                Text(
                  'max. per day',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w600, // 👈 new
                  ),
                ),
                const SizedBox(height: 22), // 👈 was 20
                Text(
                  'For 5min each time',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w600, // 👈 new
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), // 👈 was 16/8
                  decoration: BoxDecoration(
                    color: AppColors.accent(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '= ${_dailyTotalMinutes}min/day',
                    style: AppTextStyles.bodyLarge.copyWith( // 👈 was bodyMedium
                      color: AppColors.accent(context),
                      fontWeight: FontWeight.w800, // 👈 was w700
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28), // 👈 was 24
          if (!isEditing)
            LippedButton( // 👈 was SizedBox + ElevatedButton
              onTap: _packageName == null ? null : _save,
              color: AppColors.accent(context), // 👈 was backgroundCard — now uses the accent color as a real primary CTA
              lipColor: Color.lerp(AppColors.accent(context), Colors.black, 0.18),
              height: 58,
              borderRadius: BorderRadius.circular(50),
              enabled: _packageName != null,
              child: Text(
                '+ Add',
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 18, // 👈 was 17
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentText(context),
                ),
              ),
            )
          else
            LippedButton( // 👈 was SizedBox + ElevatedButton
              onTap: _delete,
              color: AppColors.error(context).withValues(alpha: 0.15),
              lipColor: AppColors.error(context).withValues(alpha: 0.35),
              height: 58,
              borderRadius: BorderRadius.circular(50),
              child: Text(
                'Delete',
                style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error(context),
                ),
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
        width: 44, // 👈 was 40 — bigger
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.backgroundSubtle(context).withValues(alpha: 0.5)
              : AppColors.backgroundSubtle(context),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary(context), size: 20), // 👈 was 18
      ),
    );
  }

  Future<void> _save() async {
    if (_packageName == null) return;
    try {
      await ref.read(lockAppViewModelProvider.notifier).saveConfig(
        existingId: _pendingConfigId ?? widget.existingConfig?.id,
        name: _appName ?? '',
        packageName: _packageName!,
        appName: _appName ?? '',
        maxUnlocks: _maxUnlocks,
        iconUrl: _iconUrl ?? '',
      );
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      debugPrint('❌ LockAppSheet save error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    if (widget.existingConfig == null) return;
    await ref.read(lockAppViewModelProvider.notifier).deleteConfig(widget.existingConfig!.id);
    if (mounted) Navigator.pop(context);
  }
}