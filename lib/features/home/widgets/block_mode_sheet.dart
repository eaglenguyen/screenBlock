import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/platform/ios_blocking_service.dart';
import '../../../providers/blocking_service_provider.dart';
import '../../../providers/premium_provider.dart';
import '../../paywall/feature_paywall_screen.dart';
import '../home_viewmodel.dart';
import 'app_list_sheet.dart';

class BlockModeSheet extends ConsumerStatefulWidget {
  const BlockModeSheet({super.key});

  @override
  ConsumerState<BlockModeSheet> createState() =>
      _BlockModeSheetState();
}

class _BlockModeSheetState extends ConsumerState<BlockModeSheet> {

  late String _selectedMode;
  late List<String> _blockedApps;
  late List<String> _allowedApps;

  @override
  void initState() {
    super.initState();
    final state = ref.read(homeViewModelProvider);
    _selectedMode = state.blockingType;
    _blockedApps = List<String>.from(state.blockedApps);
    _allowedApps = List<String>.from(state.allowedApps);
  }

  bool get _isAllApps =>
      _selectedMode == AppConstants.blockingTypeAllApps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration:  BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            const SizedBox(height: 16),
            _buildTitle(),
            const SizedBox(height: 20),
            _buildSegmentedControl(),
            const SizedBox(height: 20),
            _buildAppListRow(),
            const SizedBox(height: 20),
            _buildSetModeButton(),
          ],
        ),
      ),
    );
  }

  // ── Handle ───────────────────────────────────────
  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border(context),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Title ────────────────────────────────────────
  Widget _buildTitle() {
    return Text(
      'Block Mode',
      style: AppTextStyles.headlineMedium,
    );
  }

  // ── Segmented control ────────────────────────────
  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.border(context),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          _segmentButton(
            label: 'All Apps',
            badge: "Pro",
            isActive: _isAllApps,
            onTap: () {
              // 👇 gate — all apps is premium only
              final isPremium = ref.read(isPremiumProvider);
              if (!isPremium) {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  useRootNavigator: true,
                  builder: (_) => const FeaturePaywallScreen(),
                );
                return;
              }
              setState(() => _selectedMode = AppConstants.blockingTypeAllApps);
            },
          ),
          _segmentButton(
            label: 'Specific Apps',
            isActive: !_isAllApps,
            onTap: () => setState(() =>
            _selectedMode =
                AppConstants.blockingTypeSpecificApps),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive
                      ? AppColors.goldText(context)
                      : AppColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.goldText(context).withValues(alpha: 0.15)
                        : AppColors.gold(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActive
                          ? AppColors.goldText(context)
                          : AppColors.gold(context),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── App list row ─────────────────────────────────
  Widget _buildAppListRow() {
    final isAllApps = _isAllApps;
    final title = isAllApps ? 'Allowed Apps' : 'Blocked Apps';
    final subtitle = isAllApps
        ? 'All apps except these will be blocked'
        : 'Only these apps will be blocked';
    final count = isAllApps
        ? _allowedApps.length
        : _blockedApps.length;

    return GestureDetector(
      onTap: () => _openAppListSheet(isAllApps),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border(context),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold(context)
                                .withOpacity(0.15),
                            borderRadius:
                            BorderRadius.circular(50),
                          ),
                          child: Text(
                            '$count',
                            style: AppTextStyles.bodySmall
                                .copyWith(
                              color: AppColors.gold(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
             Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── App list bottom sheet ────────────────────────
  void _openAppListSheet(bool isAllApps) {
    if (Platform.isIOS) {
      // iOS uses FamilyActivityPicker
      _showIOSAppPicker(isAllApps);
    } else {
      // Android uses our custom AppListSheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AppListSheet(
          isBlockList: !isAllApps,
          initialApps: isAllApps
              ? _allowedApps
              : _blockedApps,
          onSave: (apps) {
            setState(() {
              if (isAllApps) {
                _allowedApps = apps;
              } else {
                _blockedApps = apps;
              }
            });
          },
        ),
      );
    }
  }

  Future<void> _showIOSAppPicker(bool isAllApps) async {
    try {
      final service = ref.read(blockingServiceProvider)
      as IOSBlockingService;

      final count = await service.showAppPicker(
        blockingMode: isAllApps
            ? AppConstants.blockingTypeAllApps
            : AppConstants.blockingTypeSpecificApps,
      );

      if (!mounted) return;

      // 👇 always update state regardless of count
      setState(() {
        final placeholders = List.generate(
          count ?? 0,
              (i) => 'ios_app_$i',
        );
        if (isAllApps) {
          _allowedApps = placeholders;
        } else {
          _blockedApps = placeholders;
        }
      });


    } catch (e) {
      debugPrint('❌ iOS app picker error: $e');
    }
  }

  // ── Set mode button ──────────────────────────────
  Widget _buildSetModeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _onSetMode,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold(context),
          foregroundColor: AppColors.goldText(context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge,
        ),
        child: const Text('Set Mode'),
      ),
    );
  }

  void _onSetMode() {
    FocusScope.of(context).unfocus(); // 👈 dismiss keyboard first
    ref.read(homeViewModelProvider.notifier)
      ..setBlockingType(_selectedMode)
      ..setBlockedApps(List<String>.from(_blockedApps))
      ..setAllowedApps(List<String>.from(_allowedApps));
    Navigator.pop(context);
  }
}