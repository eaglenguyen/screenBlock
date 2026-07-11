import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/UI/schedule/widgets/schedule_presets.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/hivebox_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/schedule.dart';
import '../../../../domain/platform/ios_blocking_service.dart';
import '../../../../paywall/feature_paywall_screen.dart';
import '../../../../providers/blocking_service_provider.dart';
import '../../../../providers/premium_provider.dart';
import '../../../../services/schedule_checker.dart';

import '../../../featuress/timelimit/time_limit_viewmodel.dart';
import '../../home/home_viewmodel.dart';
import '../../home/widgets/app_list_sheet.dart';
import '../schedule_viewmodel.dart';

class SessionBottomSheet extends ConsumerStatefulWidget {
  const SessionBottomSheet({
    super.key,
    this.existingSchedule,
    this.preset,
  });

  final Schedule? existingSchedule;
  final SchedulePreset? preset;

  @override
  ConsumerState<SessionBottomSheet> createState() =>
      _SessionBottomSheetState();
}

class _SessionBottomSheetState extends ConsumerState<SessionBottomSheet> {

  late TextEditingController _nameController;
  late String _startTime;
  late String _endTime;
  late List<int> _selectedDays;
  late String _blockingType;
  late List<String> _blockedApps;
  late List<String> _allowedApps;

  bool get isEditing => widget.existingSchedule != null;
  bool _isAllDay = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existingSchedule;
    final p = widget.preset;

    _nameController = TextEditingController(text: s?.name ?? p?.name ?? '');
    _startTime = s?.startTime ?? p?.startTime ?? '09:00';
    _endTime = s?.endTime ?? p?.endTime ?? '17:00';
    _selectedDays = s?.days ?? p?.days ?? [0, 1, 2, 3, 4];
    _blockingType = s?.blockingType ?? p?.blockingType ?? AppConstants.blockingTypeSpecificApps;
    _blockedApps = List.from(s?.blockedApps ?? []);
    _allowedApps = List.from(s?.allowedApps ?? []);
    _isAllDay = _startTime == '00:00' && _endTime == '23:59';
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
            _buildNameRow(context),
            const SizedBox(height: 8),
            _buildAllDayToggle(context),
            const SizedBox(height: 8),
            if (!_isAllDay) ...[
              _buildTimeCard(context),
              const SizedBox(height: 8),
            ],
            _buildBlockingTypeRow(context),
            const SizedBox(height: 8),
            _buildListRow(context),
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
          const Text('🧘', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _nameController,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: 'Session name',
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

  Widget _buildAllDayToggle(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAllDay = !_isAllDay;
          if (_isAllDay) {
            _startTime = '00:00';
            _endTime = '23:59';
          } else {
            _startTime = '09:00';
            _endTime = '17:00';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isAllDay
                ? AppColors.gold(context).withValues(alpha: 0.4)
                : AppColors.border(context),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Text('☀️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All Day',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: _isAllDay
                    ? AppColors.gold(context)
                    : AppColors.backgroundSubtle(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context), width: 0.5),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _isAllDay ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary(context),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        children: [
          _timeRow(context, 'Starts', _formatDisplayTime(_startTime), () async {
            final t = await _pickTime(context, _startTime);
            if (t != null) setState(() => _startTime = t);
          }),
          Divider(height: 0.5, thickness: 0.5, color: AppColors.border(context), indent: 16, endIndent: 16),
          _timeRow(context, 'Ends', _formatDisplayTime(_endTime), () async {
            final t = await _pickTime(context, _endTime);
            if (t != null) setState(() => _endTime = t);
          }),
        ],
      ),
    );
  }

  Widget _timeRow(BuildContext context, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context))),
            const Spacer(),
            Text(value, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.gold(context))),
          ],
        ),
      ),
    );
  }
  Widget _buildBlockingTypeRow(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final isAllApps = _blockingType == AppConstants.blockingTypeAllApps;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Row(
        children: [
          Text(
            'Blocking Type',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            color: AppColors.backgroundCard(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.border(context), width: 0.5),
            ),
            onSelected: (value) {
              if (value == AppConstants.blockingTypeAllApps && !isPremium) {
                Navigator.pop(context);
                Future.microtask(() {
                  Navigator.of(context, rootNavigator: true).push(
                    ModalBottomSheetRoute(
                      builder: (_) => const FeaturePaywallScreen(source: 'block_all_apps',),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                    ),
                  );
                });
                return;
              }
              setState(() => _blockingType = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AppConstants.blockingTypeSpecificApps,
                child: Row(
                  children: [
                    Icon(
                      Icons.apps_rounded,
                      color: !isAllApps
                          ? AppColors.gold(context)
                          : AppColors.textSecondary(context),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Specific Apps',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: !isAllApps
                            ? AppColors.gold(context)
                            : AppColors.textPrimary(context),
                        fontWeight: !isAllApps
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (!isAllApps) ...[
                      const Spacer(),
                      Icon(Icons.check_rounded,
                          color: AppColors.gold(context), size: 16),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppConstants.blockingTypeAllApps,
                child: Row(
                  children: [
                    Icon(
                      Icons.block_rounded,
                      color: isAllApps
                          ? AppColors.gold(context)
                          : AppColors.textSecondary(context),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'All Apps',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isAllApps
                            ? AppColors.gold(context)
                            : AppColors.textPrimary(context),
                        fontWeight: isAllApps
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isAllApps)
                      Icon(Icons.check_rounded,
                          color: AppColors.gold(context), size: 16),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            color: AppColors.goldText(context),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                ),
              ),
            ],
            child: Row(
              children: [
                Text(
                  isAllApps ? 'All Apps' : 'Specific Apps',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.gold(context),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.gold(context),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _openAppPicker(bool isAllApps) {
    if (Platform.isIOS) {
      _showIOSAppPicker(isAllApps);
    } else {
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
  }

  Future<void> _showIOSAppPicker(bool isAllApps) async {
    try {
      final service = ref.read(blockingServiceProvider) as IOSBlockingService;
      final count = await service.showAppPicker(
        blockingMode: isAllApps
            ? AppConstants.blockingTypeAllApps
            : AppConstants.blockingTypeSpecificApps,
      );

      if (!mounted) return;

      // free limit exceeded — paywall
      if (!isAllApps && count == AppConstants.freeTrackedAppsLimit + 1) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useRootNavigator: true,
          builder: (_) => const FeaturePaywallScreen(source: "multiple_schedules"),
        );
        return;
      }

      // 👇 always update state regardless of count
      setState(() {
        final placeholders = List.generate(count ?? 0, (i) => 'ios_app_$i');
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

  Widget _buildListRow(BuildContext context) {
    final isAllApps = _blockingType == AppConstants.blockingTypeAllApps;
    final count = isAllApps ? _allowedApps.length : _blockedApps.length;

    return GestureDetector(
      onTap: () => _openAppPicker(isAllApps),
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
                        isAllApps ? 'Allow List' : 'Block List',
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
                    isAllApps
                        ? 'All apps except these will be blocked'
                        : 'Only these apps will be blocked',
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
        child: const Text('Delete Session'),
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
          title: Text('Delete Session', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)), textAlign: TextAlign.center),
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

  Future<String?> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.gold(context),
            onSurface: AppColors.textPrimary(context),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _onSave() async {
    if (_nameController.text.trim().isEmpty) return;
    final startParts = _startTime.split(':');
    final endParts = _endTime.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    if (startMinutes == endMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start and end time cannot be the same'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // 👇 check for overlapping schedules
    final conflict = _findConflict(startMinutes, endMinutes);
    if (conflict != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundCard(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Schedule Conflict',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary(context),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  'This schedule overlaps with "${conflict.name}"',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  conflict.timeRange,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gold(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please choose a different time or days.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold(context),
                    foregroundColor: AppColors.goldText(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 👇 new — check for conflicts against existing time-limit configs, per app
    // 👇 check for conflicts against existing time-limit configs, per app
    final allApps = {..._blockedApps, ..._allowedApps};
    for (final packageName in allApps) {
      final timeLimitConflict = ref.read(timeLimitViewModelProvider.notifier).findAppLimitConflict(
        packageName: packageName,
        selectedDays: _selectedDays,
      );
      if (timeLimitConflict != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.backgroundCard(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Conflict Found',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary(context),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'One of the apps in this schedule already has a time limit set under "${timeLimitConflict.name}"',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please remove that app or choose different days.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold(context),
                      foregroundColor: AppColors.goldText(context),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    await ref.read(scheduleViewModelProvider.notifier).saveSchedule(
      existingId: widget.existingSchedule?.id,
      name: _nameController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      days: _selectedDays,
      blockingType: _blockingType,
      blockedApps: _blockedApps,
      allowedApps: _allowedApps,
    );
    if (mounted) Navigator.pop(context);
  }

  Schedule? _findConflict(int newStart, int newEnd) {
    final box = Hive.box<Schedule>(HiveBoxNames.schedules);
    final existing = box.values.toList();

    for (final s in existing) {
      // skip the schedule being edited
      if (s.id == widget.existingSchedule?.id) continue;

      final sParts = s.startTime.split(':');
      final eParts = s.endTime.split(':');
      final sStart = int.parse(sParts[0]) * 60 + int.parse(sParts[1]);
      final sEnd = int.parse(eParts[0]) * 60 + int.parse(eParts[1]);

      // check if any selected days overlap
      final sharedDays = _selectedDays
          .where((d) => s.days.contains(d))
          .toList();
      if (sharedDays.isEmpty) continue;

      // check if time ranges overlap
      final overlaps = newStart < sEnd && newEnd > sStart;
      if (overlaps) return s;
    }
    return null;
  }

  Future<void> _onDelete() async {
    if (widget.existingSchedule == null) return;
    final homeNotifier = ref.read(homeViewModelProvider.notifier);
    final homeState = ref.read(homeViewModelProvider);
    if (homeState.isScheduleActive || homeState.isSchedulePaused) {
      homeNotifier.resumeSchedule();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await ref.read(scheduleViewModelProvider.notifier).deleteSchedule(widget.existingSchedule!.id);
    ScheduleChecker.instance.checkNow();
    if (mounted) Navigator.pop(context);
  }

  String _formatDisplayTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}