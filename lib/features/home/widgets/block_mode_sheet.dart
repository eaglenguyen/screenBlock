import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
    _blockedApps = List.from(state.blockedApps);
    _allowedApps = List.from(state.allowedApps);
  }

  bool get _isAllApps =>
      _selectedMode == AppConstants.blockingTypeAllApps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
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
        color: AppColors.border,
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
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          _segmentButton(
            label: 'All Apps',
            isActive: _isAllApps,
            onTap: () => setState(() =>
            _selectedMode = AppConstants.blockingTypeAllApps),
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
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold
                : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive
                  ? AppColors.goldText
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
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
          color: AppColors.backgroundSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
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
                            color: AppColors.gold
                                .withOpacity(0.15),
                            borderRadius:
                            BorderRadius.circular(50),
                          ),
                          child: Text(
                            '$count',
                            style: AppTextStyles.bodySmall
                                .copyWith(
                              color: AppColors.gold,
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── App list bottom sheet ────────────────────────
  void _openAppListSheet(bool isAllApps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => AppListSheet(
        isBlockList: !isAllApps,
        initialApps: isAllApps ? _allowedApps : _blockedApps,
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

  // ── Set mode button ──────────────────────────────
  Widget _buildSetModeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _onSetMode,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.goldText,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge,
        ),
        child: const Text('Set Mode'),
      ),
    );
  }

  void _onSetMode() {
    ref.read(homeViewModelProvider.notifier)
      ..setBlockingType(_selectedMode)
      ..setBlockedApps(_blockedApps)
      ..setAllowedApps(_allowedApps);
    Navigator.pop(context);
  }
}