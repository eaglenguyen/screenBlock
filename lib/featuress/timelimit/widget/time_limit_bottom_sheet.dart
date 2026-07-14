import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/time_limit_config.dart';
import '../../../../domain/platform/ios_blocking_service.dart';
import '../../../../providers/blocking_service_provider.dart';
import '../../../UI/home/widgets/app_list_sheet.dart';
import '../../../core/constants/app_constants.dart';
import '../../../featuress/timelimit/time_limit_viewmodel.dart';
import '../../../paywall/feature_paywall_screen.dart';

class TimeLimitBottomSheet extends ConsumerStatefulWidget {
  const TimeLimitBottomSheet({
    super.key,
    this.existingConfig,
  });

  final TimeLimitConfig? existingConfig;

  @override
  ConsumerState<TimeLimitBottomSheet> createState() =>
      _TimeLimitBottomSheetState();
}

class _TimeLimitBottomSheetState extends ConsumerState<TimeLimitBottomSheet> {

  late TextEditingController _nameController;
  late int _limitMinutes;
  late List<int> _selectedDays;
  late List<String> _packageNames;
  late final String _configId;


  bool get isEditing => widget.existingConfig != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingConfig;

    _nameController = TextEditingController(text: c?.name ?? '');
    _limitMinutes = c?.limitMinutes ?? 30;
    _selectedDays = List.from(c?.days ?? [0, 1, 2, 3, 4]);
    _packageNames = List.from(c?.packageNames ?? []);

    _configId = c?.id ?? const Uuid().v4();

  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Time Limit',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildNameRow(context),
            const SizedBox(height: 8),
            _buildLimitCard(context),
            const SizedBox(height: 8),
            _buildAppListRow(context),
            const SizedBox(height: 8),
            _buildDayPicker(context),
            const SizedBox(height: 16),
            _buildSaveButton(context),
            if (isEditing) ...[
              const SizedBox(height: 10),
              _buildDeleteButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNameRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Row(
        children: [
          const Text('⏱️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _nameController,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: 'Limit name',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary(context),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.edit_outlined, color: AppColors.textSecondary(context), size: 16),
        ],
      ),
    );
  }

  Widget _buildLimitCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daily limit',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context)),
              ),
              const Spacer(),
              Text(
                _formatMinutes(_limitMinutes),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.gold(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 👇 new — preset row
          Row(
            children: [
              Expanded(child: _presetChip(context, label: '30m', minutes: 30)),
              const SizedBox(width: 8),
              Expanded(child: _presetChip(context, label: '1h', minutes: 60)),
              const SizedBox(width: 8),
              Expanded(child: _presetChip(context, label: '2h', minutes: 120)),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.gold(context),
              inactiveTrackColor: AppColors.gold(context).withValues(alpha: 0.15),
              thumbColor: AppColors.gold(context),
              overlayColor: AppColors.gold(context).withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              trackHeight: 4,
            ),
            child: Slider(
              value: _limitMinutes.toDouble(),
              min: 1,
              max: 240,
              divisions: 239,
              onChanged: (v) => setState(() => _limitMinutes = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1m', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
              Text('4h', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(BuildContext context, {required String label, required int minutes}) {
    final isSelected = _limitMinutes == minutes;
    return GestureDetector(
      onTap: () => setState(() => _limitMinutes = minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold(context) : AppColors.backgroundCard(context),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.gold(context) : AppColors.border(context),
            width: isSelected ? 0 : 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? AppColors.goldText(context) : AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  void _openAppPicker() {
    if (Platform.isIOS) {
      _showIOSAppPicker();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (_) => AppListSheet(
          isBlockList: true,
          initialApps: _packageNames,
          onSave: (apps) {
            setState(() => _packageNames = apps);
          },
        ),
      );
    }
  }

  Future<void> _showIOSAppPicker() async {
    try {
      final service = ref.read(blockingServiceProvider) as IOSBlockingService;
      final count = await service.showTimeLimitAppPicker(configId: _configId);

      if (!mounted) return;

      setState(() {
        _packageNames = List.generate(count ?? 0, (i) => 'ios_app_$i');
      });
    } catch (e) {
      debugPrint('❌ iOS time-limit app picker error: $e');
    }
  }

  Widget _buildAppListRow(BuildContext context) {
    final count = _packageNames.length;

    return GestureDetector(
      onTap: _openAppPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context), width: 0.5),
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
                        'Apps',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold(context).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '$count',
                            style: AppTextStyles.bodySmall.copyWith(
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
                    'Each app gets its own daily limit',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPicker(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('On these days:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary(context))),
              const Spacer(),
              Text(_getDaysLabel(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold(context))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index);
              return GestureDetector(
                onTap: () => _toggleDay(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold(context) : AppColors.backgroundCard(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.gold(context) : AppColors.border(context),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      days[index],
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected ? AppColors.goldText(context) : AppColors.textSecondary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold(context),
          foregroundColor: AppColors.goldText(context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge,
        ),
        child: const Text('Save'),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showDeleteConfirmation,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error(context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          side: BorderSide(color: AppColors.error(context), width: 0.5),
        ),
        child: const Text('Delete Time Limit'),
      ),
    );
  }

  void _showDeleteConfirmation() {
    final confirmController = TextEditingController();
    const confirmWord = 'delete';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Delete Time Limit', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Type Delete to confirm:',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '"$confirmWord"',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error(context), fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary(context)),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type DELETE here',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                  filled: true,
                  fillColor: AppColors.backgroundSubtle(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border(context))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.error(context))),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: confirmController.text.trim().toLowerCase() == confirmWord.toLowerCase()
                        ? () { Navigator.pop(ctx); _onDelete(); }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error(context),
                      disabledBackgroundColor: AppColors.error(context).withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary(context),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      side: BorderSide(color: AppColors.border(context)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  String _getDaysLabel() {
    if (_selectedDays.length == 7) return 'Every day';
    if (_selectedDays.length == 5 && !_selectedDays.contains(5) && !_selectedDays.contains(6)) return 'Weekdays';
    if (_selectedDays.length == 2 && _selectedDays.contains(5) && _selectedDays.contains(6)) return 'Weekends';
    return 'Custom';
  }

  Future<void> _onSave() async {
    if (_nameController.text.trim().isEmpty) return;
    if (_packageNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one app'), backgroundColor: Colors.red),
      );
      return;
    }

    await ref.read(timeLimitViewModelProvider.notifier).saveConfig(
      existingId: _configId,
      name: _nameController.text.trim(),
      packageNames: _packageNames,
      limitMinutes: _limitMinutes,
      days: _selectedDays,
      isNew: !isEditing,
    );
    if (mounted) Navigator.pop(context);
  }



  Future<void> _onDelete() async {
    if (widget.existingConfig == null) return;
    await ref.read(timeLimitViewModelProvider.notifier).deleteConfig(widget.existingConfig!.id);
    if (mounted) Navigator.pop(context);
  }


}