import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/schedule.dart';
import '../../../../domain/platform/ios_blocking_service.dart';
import '../../../../providers/blocking_service_provider.dart';
import '../../../../services/schedule_checker.dart';
import '../../home_viewmodel.dart';
import '../../widgets/app_list_sheet.dart';
import '../schedule_viewmodel.dart';


class SessionBottomSheet extends ConsumerStatefulWidget {
  const SessionBottomSheet({
    super.key,
    this.existingSchedule,
  });

  final Schedule? existingSchedule;

  @override
  ConsumerState<SessionBottomSheet> createState() =>
      _SessionBottomSheetState();
}

class _SessionBottomSheetState
    extends ConsumerState<SessionBottomSheet> {

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
    _nameController = TextEditingController(
      text: s?.name ?? '',
    );
    _startTime = s?.startTime ?? '09:00';
    _endTime = s?.endTime ?? '17:00';
    _selectedDays = s?.days ?? [0, 1, 2, 3, 4];
    _blockingType = s?.blockingType ??
        AppConstants.blockingTypeAllApps;
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
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Scheduled Session',
                style: AppTextStyles.bodySmall,
              ),
            ),
            const SizedBox(height: 8),

            // session name
            _buildNameRow(),
            const SizedBox(height: 8),

            // 👇 add all day toggle here
            _buildAllDayToggle(),
            const SizedBox(height: 8),

            // time card — hidden when all day is on
            if (!_isAllDay) ...[
              _buildTimeCard(),
              const SizedBox(height: 8),
            ],
            // blocking type
            _buildBlockingTypeRow(),
            const SizedBox(height: 8),

            // list selector
            _buildListRow(),
            const SizedBox(height: 8),

            // day picker
            _buildDayPicker(),
            const SizedBox(height: 16),

            // xp reward
            _buildXpRow(),
            const SizedBox(height: 20),

            // save button
            _buildSaveButton(),

            // delete button — edit mode only
            if (isEditing) ...[
              const SizedBox(height: 10),
              _buildDeleteButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNameRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Text('🧘', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _nameController,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Session name',
                hintStyle: AppTextStyles.bodyMedium,
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(
            Icons.edit_outlined,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildAllDayToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAllDay = !_isAllDay;
          if (_isAllDay) {
            _startTime = '00:00';
            _endTime = '23:59';
          } else {
            // restore defaults when turning off
            _startTime = '09:00';
            _endTime = '17:00';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isAllDay
                ? AppColors.gold.withValues(alpha: 0.4)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Text('☀️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('All Day', style: AppTextStyles.bodyLarge),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: _isAllDay
                    ? AppColors.gold
                    : AppColors.backgroundSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 0.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _isAllDay
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
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

  Widget _buildTimeCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _timeRow('Starts', _formatDisplayTime(_startTime), () async {
            final t = await _pickTime(context, _startTime);
            if (t != null) setState(() => _startTime = t);
          }),
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.border,
            indent: 16,
            endIndent: 16,
          ),
          _timeRow('Ends', _formatDisplayTime(_endTime), () async {
            final t = await _pickTime(context, _endTime);
            if (t != null) setState(() => _endTime = t);
          }),
        ],
      ),
    );
  }

  Widget _timeRow(
      String label,
      String value,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.bodyLarge),
            const Spacer(),
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockingTypeRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Blocking Type',
            style: AppTextStyles.bodyLarge,
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleBlockingType,
            child: Row(
              children: [
                Text(
                  _blockingType ==
                      AppConstants.blockingTypeAllApps
                      ? 'All Apps'
                      : 'Specific Apps',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.gold,
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
      final service = ref.read(blockingServiceProvider)
      as IOSBlockingService;

      final count = await service.showAppPicker(
        blockingMode: isAllApps
            ? AppConstants.blockingTypeAllApps
            : AppConstants.blockingTypeSpecificApps,
      );

      if (mounted && (count ?? 0) > 0) {
        setState(() {
          final placeholders = List.generate(
            count!,
                (i) => 'ios_app_$i',
          );
          if (isAllApps) {
            _allowedApps = placeholders;
          } else {
            _blockedApps = placeholders;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ iOS app picker error: $e');
    }
  }

  Widget _buildListRow() {
    final isAllApps = _blockingType == AppConstants.blockingTypeAllApps;
    final count = isAllApps ? _allowedApps.length : _blockedApps.length;

    return GestureDetector(
      onTap: () => _openAppPicker(isAllApps),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle,
          borderRadius: BorderRadius.circular(14),
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
                        isAllApps ? 'Allow List' : 'Block List',
                        style: AppTextStyles.bodyLarge,
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '$count',
                            style: AppTextStyles.bodySmall.copyWith(
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
                    isAllApps
                        ? 'All apps except these will be blocked'
                        : 'Only these apps will be blocked',
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

  Widget _buildDayPicker() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'On these days:',
                style: AppTextStyles.bodyMedium,
              ),
              const Spacer(),
              Text(
                _getDaysLabel(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isSelected =
              _selectedDays.contains(index);
              return GestureDetector(
                onTap: () => _toggleDay(index),
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold
                        : AppColors.backgroundCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.gold
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      days[index],
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.goldText
                            : AppColors.textSecondary,
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

  Widget _buildXpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('⚡', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          "You'll earn ",
          style: AppTextStyles.bodyMedium,
        ),
        Text(
          '10 XP',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          ' for each session',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.goldText,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelLarge,
        ),
        child: const Text('Save'),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _onDelete,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          side: const BorderSide(
            color: AppColors.error,
            width: 0.5,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.error,
          ),
        ),
        child: const Text('Delete Session'),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────
  void _toggleBlockingType() {
    setState(() {
      _blockingType =
      _blockingType == AppConstants.blockingTypeAllApps
          ? AppConstants.blockingTypeSpecificApps
          : AppConstants.blockingTypeAllApps;
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        }
      } else {
        _selectedDays.add(day);
      }
    });
  }

  String _getDaysLabel() {
    if (_selectedDays.length == 7) return 'Every day';
    if (_selectedDays.length == 5 &&
        !_selectedDays.contains(5) &&
        !_selectedDays.contains(6)) return 'Weekdays';
    if (_selectedDays.length == 2 &&
        _selectedDays.contains(5) &&
        _selectedDays.contains(6)) return 'Weekends';
    return 'Custom';
  }

  Future<String?> _pickTime(
      BuildContext context,
      String current,
      ) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _onSave() async {
    if (_nameController.text.trim().isEmpty) return;

    // validate times
    final startParts = _startTime.split(':');
    final endParts = _endTime.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    // allow overnight (end < start) but not equal
    if (startMinutes == endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start and end time cannot be the same'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref
        .read(scheduleViewModelProvider.notifier)
        .saveSchedule(
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

  Future<void> _onDelete() async {
    if (widget.existingSchedule == null) return;

    // 👇 if this schedule is currently paused or active, stop it
    final homeNotifier = ref.read(homeViewModelProvider.notifier);
    final homeState = ref.read(homeViewModelProvider);

    if (homeState.isScheduleActive || homeState.isSchedulePaused) {
      homeNotifier.resumeSchedule(); // clears pause timer
      // small delay then stop
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await ref
        .read(scheduleViewModelProvider.notifier)
        .deleteSchedule(widget.existingSchedule!.id);

    // force schedule checker to re-evaluate
    ScheduleChecker.instance.checkNow();

    if (mounted) Navigator.pop(context);
  }

  String _formatDisplayTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}