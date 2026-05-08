import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/schedule.dart';
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

  bool get isEditing => widget.existingSchedule != null;

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

            // time card
            _buildTimeCard(),
            const SizedBox(height: 8),

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
          _timeRow('Starts', _startTime, () async {
            final t = await _pickTime(
              context, _startTime,
            );
            if (t != null) setState(() => _startTime = t);
          }),
          const Divider(
            height: 0.5,
            thickness: 0.5,
            color: AppColors.border,
            indent: 16,
            endIndent: 16,
          ),
          _timeRow('Ends', _endTime, () async {
            final t = await _pickTime(
              context, _endTime,
            );
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

  Widget _buildListRow() {
    final isAllApps =
        _blockingType == AppConstants.blockingTypeAllApps;
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
                isAllApps ? 'Allow List' : 'Block List',
                style: AppTextStyles.bodyLarge,
              ),
              const Spacer(),
              const Icon(
                Icons.apps_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
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

    await ref
        .read(scheduleViewModelProvider.notifier)
        .saveSchedule(
      existingId: widget.existingSchedule?.id,
      name: _nameController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      days: _selectedDays,
      blockingType: _blockingType,
      blockedApps:
      widget.existingSchedule?.blockedApps ?? [],
      allowedApps:
      widget.existingSchedule?.allowedApps ?? [],
    );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _onDelete() async {
    if (widget.existingSchedule == null) return;

    await ref
        .read(scheduleViewModelProvider.notifier)
        .deleteSchedule(widget.existingSchedule!.id);

    if (mounted) Navigator.pop(context);
  }
}