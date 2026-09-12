import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pausenow/UI/schedule/widgets/schedule_presets.dart';
import 'package:uuid/uuid.dart';

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

import '../../home/home_viewmodel.dart';
import '../../home/widgets/app_list_sheet.dart';
import '../schedule_viewmodel.dart';
import 'hold_to_confirm.dart';

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
  late final String _configId;

  bool get _canSave {
    final isAllApps = _blockingType == AppConstants.blockingTypeAllApps;
    final relevantApps = isAllApps ? _allowedApps : _blockedApps;
    return _nameController.text.trim().isNotEmpty && relevantApps.isNotEmpty;
  }

  final FocusNode _nameFocusNode = FocusNode(); // 👈 new

  // 👇 moved here from inside _buildDayPicker
  static const _everyDayColor = Color(0xFFA8DCC6); // darker pastel teal
  static const _weekdaysColor = Color(0xFF6BAED6);
  static const _weekendsColor = Color(0xFFF0B27A);
  static const _customDayColors = [
    Color(0xFFD4C9F0),
    Color(0xFFA8DCC6),
    Color(0xFFF5C4B3),
    Color(0xFFF4C0D1),
    Color(0xFFB5D4F4),
    Color(0xFFC0DD97),
    Color(0xFFFAC775),
  ];

  Color _colorForDay(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return AppColors.accent(context);
    switch (_getDaysLabel()) {
      case 'Every day':
        return _everyDayColor;
      case 'Weekdays':
        return _weekdaysColor;
      case 'Weekends':
        return _weekendsColor;
      default:
        return _customDayColors[index];
    }
  }

  // 👇 new — the overall "current combo" color, used by the toggle
  Color get _currentComboColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return AppColors.accent(context);
    switch (_getDaysLabel()) {
      case 'Every day':
        return _everyDayColor;
      case 'Weekdays':
        return _weekdaysColor;
      case 'Weekends':
        return _weekendsColor;
      default:
        return _customDayColors.first; // 👈 Custom has no single color — defaults to the first day's pastel
    }
  }


  @override
  void initState() {
    super.initState();
    final s = widget.existingSchedule;
    final p = widget.preset;

    _nameController = TextEditingController(text: s?.name ?? p?.name ?? 'Blocked Apps');
    _startTime = s?.startTime ?? p?.startTime ?? '09:00';
    _endTime = s?.endTime ?? p?.endTime ?? '17:00';
    _selectedDays = s?.days ?? p?.days ?? [0, 1, 2, 3, 4];
    _blockingType = s?.blockingType ?? p?.blockingType ?? AppConstants.blockingTypeSpecificApps;
    _blockedApps = List.from(s?.blockedApps ?? []);
    _allowedApps = List.from(s?.allowedApps ?? []);
    _isAllDay = _startTime == '00:00' && _endTime == '23:59';
    _configId = s?.id ?? const Uuid().v4();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose(); // 👈 new
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.95,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), // 👈 bigger radius
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44, // 👈 chunkier handle
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              _buildHeader(context), // 👈 new — playful title with emoji
              const SizedBox(height: 20),
              _buildNameRow(context),
              const SizedBox(height: 12),
              _buildAllDayToggle(context),
              const SizedBox(height: 12),
              if (!_isAllDay) ...[
                _buildTimeCard(context),
                const SizedBox(height: 12),
              ],
              _buildBlockingTypeRow(context),
              const SizedBox(height: 12),
              _buildListRow(context),
              const SizedBox(height: 12),
              _buildDayPicker(context),
              const SizedBox(height: 20),
              _buildSaveRow(context),
            ],
          ),
        ),
      ),
    );
  }

  // 👇 new — playful header
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text('🎉', style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 6),
        Text(
          isEditing ? 'Edit your session' : 'Create a session',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _buildSubtitle(), // 👈 was the static string
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }

  String _customDaysLabel() {
    const dayAbbrev = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(_selectedDays)..sort();
    return sorted.map((i) => dayAbbrev[i]).join(', ');
  }

  String _buildSubtitle() {
    final daysLabel = _getDaysLabel() == 'Custom'
        ? _customDaysLabel() // 👈 new — "Mon, Wed, Fri" instead of "custom"
        : _getDaysLabel().toLowerCase();
    final timeRange = _isAllDay
        ? 'all day'
        : '${_formatDisplayTime(_startTime)} - ${_formatDisplayTime(_endTime)}';
    return 'Block apps on $daysLabel, $timeRange.';
  }

  // 👇 shared bubbly row shell — colored icon badge + rounded 20px card
  Widget _bubbleCard({
    required BuildContext context,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _buildNameRow(BuildContext context) {
    return _bubbleCard(
      context: context,
      onTap: () => FocusScope.of(context).requestFocus(_nameFocusNode), // 👈 new — tapping anywhere in the row focuses the field
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode, // 👈 new
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Name your session',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _PulsingPencil(), // 👈 new
        ],
      ),
    );
  }


  Widget _buildAllDayToggle(BuildContext context) {
    return _bubbleCard(
      context: context,
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Always on',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 28,
            decoration: BoxDecoration(
              color: _isAllDay ? _currentComboColor : AppColors.border(context), // 👈 was AppColors.accentDark(context)
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              alignment: _isAllDay ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3, offset: const Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(BuildContext context) {
    return _bubbleCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timeRow(context, 'Starts', _formatDisplayTime(_startTime), () async {
            final t = await _pickTime(context, _startTime);
            if (t != null) setState(() => _startTime = t);
          }),
          Divider(height: 18, thickness: 0.5, color: AppColors.border(context)),
          _timeRow(context, 'Ends', _formatDisplayTime(_endTime), () async {
            final t = await _pickTime(context, _endTime);
            if (t != null) setState(() => _endTime = t);
          }),
        ],
      ),
    );
  }

  Widget _timeRow(BuildContext context, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _currentComboColor.withValues(alpha: 0.25), // 👈 was AppColors.accent(context).withValues(alpha: 0.15)
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(value, style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF2C2C2A), fontWeight: FontWeight.w700)), // 👈 dark text for contrast against light pastels
          ),
        ],
      ),
    );
  }
  Widget _buildBlockingTypeRow(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final isAllApps = _blockingType == AppConstants.blockingTypeAllApps;

    return _bubbleCard(
      context: context,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Blocking type',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700),
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.backgroundCard(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.border(context), width: 0.5),
            ),
            onSelected: (value) {
              if (value == AppConstants.blockingTypeAllApps && !isPremium) {
                Navigator.pop(context);
                Future.microtask(() {
                  Navigator.of(context, rootNavigator: true).push(
                    ModalBottomSheetRoute(
                      builder: (_) => const FeaturePaywallScreen(source: 'block_all_apps'),
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
                    Icon(Icons.apps_rounded, color: !isAllApps ? AppColors.accent(context) : AppColors.textSecondary(context), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Specific apps',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: !isAllApps ? AppColors.accent(context) : AppColors.textPrimary(context),
                        fontWeight: !isAllApps ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (!isAllApps) ...[
                      const Spacer(),
                      Icon(Icons.check_rounded, color: AppColors.accent(context), size: 16),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppConstants.blockingTypeAllApps,
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, color: isAllApps ? AppColors.accent(context) : AppColors.textSecondary(context), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'All apps',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isAllApps ? AppColors.accent(context) : AppColors.textPrimary(context),
                        fontWeight: isAllApps ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isAllApps) Icon(Icons.check_rounded, color: AppColors.accent(context), size: 16),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.accent(context), borderRadius: BorderRadius.circular(50)),
                      child: Text('PRO', style: TextStyle(color: AppColors.accentText(context), fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _currentComboColor.withValues(alpha: 0.25), // 👈 was AppColors.accent(context).withValues(alpha: 0.15)
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAllApps ? 'All apps' : 'Specific apps',
                    style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF2C2C2A), fontWeight: FontWeight.w700), // 👈 dark text instead of accent
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2C2C2A), size: 18), // 👈 dark instead of accent
                ],
              ),
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
      final count = await service.showSchedulePicker(
        scheduleId: _configId,
        blockingMode: isAllApps ? AppConstants.blockingTypeAllApps : AppConstants.blockingTypeSpecificApps,
      );

      if (!mounted) return;

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

    return _bubbleCard(
      context: context,
      onTap: () => _openAppPicker(isAllApps),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Apps', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700)),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accent(context).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(50)),
                        child: Text('$count', style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent(context), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isAllApps ? 'This app list will NOT be blocked' : 'This app list will be blocked',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          if (count == 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(50)),
              child: Text('Required', style: AppTextStyles.bodySmall.copyWith(color: Colors.amber.shade800, fontWeight: FontWeight.w700, fontSize: 10)),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary(context), size: 20),
        ],
      ),
    );
  }

  Widget _buildDayPicker(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // 👈 back to single letters
    final comboLabel = _getDaysLabel();

    return _bubbleCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Repeat on', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(comboLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index);
              final dayColor = _colorForDay(index); // 👈 shared method now
              return GestureDetector(
                onTap: () => _toggleDay(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? dayColor : AppColors.backgroundCard(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? dayColor : AppColors.border(context),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      days[index],
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected ? const Color(0xFF2C2C2A) : AppColors.textSecondary(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
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


  Widget _buildSaveRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _canSave ? _onSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent(context),
              foregroundColor: AppColors.accentText(context),
              disabledBackgroundColor: AppColors.backgroundSubtle(context),
              disabledForegroundColor: AppColors.textSecondary(context),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: const StadiumBorder(),
              elevation: 0,
              textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            child: Text(isEditing ? 'Save' : 'Schedule'), // 👈 was const Text('Schedule')
          ),
        ),
        if (isEditing) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showDeleteConfirmation,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error(context).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error(context).withValues(alpha: 0.3), width: 0.5),
              ),
              child: Icon(Icons.delete_outline_outlined, color: AppColors.error(context), size: 24),
            ),
          ),
        ],
      ],
    );
  }

  void _showDeleteConfirmation() {
    final confirmController = TextEditingController();
    const confirmWord = 'delete';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isConfirmed = confirmController.text.trim().toLowerCase() == confirmWord.toLowerCase();

          return AlertDialog(
            backgroundColor: AppColors.backgroundCard(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Are you sure you want to delete?',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Type delete to confirm:',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary(context)),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                    filled: true,
                    fillColor: AppColors.backgroundSubtle(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border(context))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.error(context))),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              Column(
                children: [
                  AbsorbPointer(
                    absorbing: !isConfirmed,
                    child: Opacity(
                      opacity: isConfirmed ? 1.0 : 0.4,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: HoldToConfirmButton(
                          onConfirmed: () {
                            Navigator.pop(ctx);
                            _onDelete();
                          },
                          color: AppColors.error(context),
                          fillColor: Color.lerp(AppColors.error(context), Colors.black, 0.3)!,
                          textColor: Colors.white,
                          label: 'Hold to Delete',
                          holdingLabel: 'Keep holding...',
                          doneLabel: 'Deleting',
                          holdDuration: const Duration(seconds: 3),
                        ),
                      ),
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
          );
        },
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

  Future<String?> _pickTimeIOS(BuildContext context, TimeOfDay initial) async {
    DateTime tempPicked = DateTime(2024, 1, 1, initial.hour, initial.minute);
    DateTime? confirmed;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: AppColors.backgroundCard(context),
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border(context), width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary(context))),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () {
                      confirmed = tempPicked;
                      Navigator.pop(ctx);
                    },
                    child: Text('Save', style: TextStyle(color: AppColors.accent(context), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(color: AppColors.textPrimary(context), fontSize: 20),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempPicked,
                  use24hFormat: false,
                  onDateTimeChanged: (dt) => tempPicked = dt,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null) return null;
    return '${confirmed!.hour.toString().padLeft(2, '0')}:${confirmed!.minute.toString().padLeft(2, '0')}';
  }

  Future<String?> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    if (Platform.isIOS) {
      return _pickTimeIOS(context, initial);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent(context),
            onSurface: AppColors.textPrimary(context),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  void _showValidationDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, textAlign: TextAlign.center, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context))),
        content: Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context))),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent(context),
                foregroundColor: AppColors.accentText(context),
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

  Future<void> _onSave() async {
    final isAllApps = _blockingType == AppConstants.blockingTypeAllApps;
    final relevantApps = isAllApps ? _allowedApps : _blockedApps;
    final startParts = _startTime.split(':');
    final endParts = _endTime.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    if (_nameController.text.trim().isEmpty) {
      _showValidationDialog(context, title: 'Name Required', message: 'Please enter a name for this session!');
      return;
    }

    if (relevantApps.isEmpty) {
      _showValidationDialog(
        context,
        title: 'No Apps Selected',
        message: isAllApps ? 'Please pick at least 1 app to add to your allow list!' : 'Please pick at least 1 app to add to block list!',
      );
      return;
    }

    if (startMinutes == endMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start and end time cannot be the same'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final conflict = _findConflict(startMinutes, endMinutes);
    if (conflict != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundCard(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Schedule Conflict', textAlign: TextAlign.center, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('This schedule overlaps with "${conflict.name}"', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context))),
                const SizedBox(height: 6),
                Text(conflict.timeRange, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent(context), fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Please choose a different time or days.', textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.accentText(context),
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

    await ref.read(scheduleViewModelProvider.notifier).saveSchedule(
      existingId: _configId,
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
      if (s.id == widget.existingSchedule?.id) continue;

      final sParts = s.startTime.split(':');
      final eParts = s.endTime.split(':');
      final sStart = int.parse(sParts[0]) * 60 + int.parse(sParts[1]);
      final sEnd = int.parse(eParts[0]) * 60 + int.parse(eParts[1]);

      final sharedDays = _selectedDays.where((d) => s.days.contains(d)).toList();
      if (sharedDays.isEmpty) continue;

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

class _PulsingPencil extends StatefulWidget {
  const _PulsingPencil();

  @override
  State<_PulsingPencil> createState() => _PulsingPencilState();
}

class _PulsingPencilState extends State<_PulsingPencil> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: child,
        ),
      ),
      child: Icon(Icons.edit_rounded, color: AppColors.accentDark(context), size: 16),
    );
  }
}