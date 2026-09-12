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
import '../../../features/timelimit/time_limit_viewmodel.dart';
import '../../../paywall/feature_paywall_screen.dart';
import '../../../providers/premium_provider.dart';

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
  bool get _isOverFreeLimit => _limitMinutes > 240;
  bool get _canSave => _nameController.text.trim().isNotEmpty && _packageNames.isNotEmpty;

  final FocusNode _nameFocusNode = FocusNode();

  static const _everyDayColor = Color(0xFFA8DCC6);
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
        return _customDayColors.first;
    }
  }

  final List<int> _limitValues = [
    5, 10, 15, 20, 25, 30,
    60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360, 390, 420, 450, 480,
  ];

  int _nearestAllowedValue(int minutes) {
    return _limitValues.reduce((a, b) => (minutes - a).abs() <= (minutes - b).abs() ? a : b);
  }

  @override
  void initState() {
    super.initState();
    final c = widget.existingConfig;
    _nameController = TextEditingController(text: c?.name ?? 'Blocked Apps');
    final loadedMinutes = c?.limitMinutes ?? 30;
    _limitMinutes = _limitValues.contains(loadedMinutes)
        ? loadedMinutes
        : _nearestAllowedValue(loadedMinutes);
    _selectedDays = List.from(c?.days ?? [0, 1, 2, 3, 4]);
    _packageNames = List.from(c?.packageNames ?? []);
    _configId = c?.id ?? const Uuid().v4();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildNameRow(context),
              const SizedBox(height: 12),
              _buildLimitCard(context),
              const SizedBox(height: 12),
              _buildAppListRow(context),
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Text('⏱️', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 6),
        Text(
          isEditing ? 'Edit time limit' : 'Set a time limit',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _buildSubtitle(),
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
        ? _customDaysLabel()
        : _getDaysLabel().toLowerCase();
    return 'Cap usage at ${_formatMinutes(_limitMinutes)}/day, $daysLabel.';
  }

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
      onTap: () => FocusScope.of(context).requestFocus(_nameFocusNode),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Name your limit',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _PulsingPencil(),
        ],
      ),
    );
  }

  Widget _buildLimitCard(BuildContext context) {
    final currentIndex = _limitValues.indexOf(_limitMinutes).clamp(0, _limitValues.length - 1);

    return _bubbleCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daily limit',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_isOverFreeLimit) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 0.5),
                  ),
                  child: Text(
                    'PRO',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isOverFreeLimit ? Colors.orange.withValues(alpha: 0.15) : _currentComboColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _formatMinutes(_limitMinutes),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _isOverFreeLimit ? Colors.orange : const Color(0xFF2C2C2A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _presetChip(context, label: '30m', minutes: 30)),
              const SizedBox(width: 8),
              Expanded(child: _presetChip(context, label: '1h', minutes: 60)),
              const SizedBox(width: 8),
              Expanded(child: _presetChip(context, label: '4h', minutes: 240)),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _isOverFreeLimit ? Colors.orange : _currentComboColor,
              inactiveTrackColor: _currentComboColor.withValues(alpha: 0.15),
              thumbColor: _isOverFreeLimit ? Colors.orange : _currentComboColor,
              overlayColor: _currentComboColor.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              trackHeight: 4,
            ),
            child: Slider(
              value: currentIndex.toDouble(),
              min: 0,
              max: (_limitValues.length - 1).toDouble(),
              divisions: _limitValues.length - 1,
              onChanged: (v) => setState(() => _limitMinutes = _limitValues[v.round()]),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatMinutes(_limitValues.first),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
              Text(_formatMinutes(_limitValues.last),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
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
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _currentComboColor : AppColors.backgroundCard(context),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? _currentComboColor : AppColors.border(context),
            width: isSelected ? 0 : 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? const Color(0xFF2C2C2A) : AppColors.textPrimary(context),
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
    return _bubbleCard(
      context: context,
      onTap: _openAppPicker,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Apps',
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          '$count',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accent(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Each app gets its own daily limit',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          if (count == 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Required',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary(context), size: 20),
        ],
      ),
    );
  }

  Widget _buildDayPicker(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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
              final dayColor = _colorForDay(index);
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
            child: const Text('Set Limit'),
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
          return AlertDialog(
            backgroundColor: AppColors.backgroundCard(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  Future<void> _onSave() async {
    if (_nameController.text.trim().isEmpty) {
      _showValidationDialog(
        context,
        title: 'Name Required',
        message: 'Please enter a name for this time limit!',
      );
      return;
    }
    if (_packageNames.isEmpty) {
      _showValidationDialog(
        context,
        title: 'No Apps Selected',
        message: 'Please pick at least 1 app to add a time limit to!',
      );
      return;
    }

    final isPremium = ref.read(isPremiumProvider);
    if (_isOverFreeLimit && !isPremium) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (_) => const FeaturePaywallScreen(source: 'time_limit_over_4h'),
      );
      return;
    }

    final notifier = ref.read(timeLimitViewModelProvider.notifier);

    await notifier.saveConfig(
      existingId: _configId,
      name: _nameController.text.trim(),
      packageNames: _packageNames,
      limitMinutes: _limitMinutes,
      days: _selectedDays,
      isNew: !isEditing,
    );

    if (isEditing) {
      await notifier.saveConfig(
        existingId: _configId,
        name: _nameController.text.trim(),
        packageNames: _packageNames,
        limitMinutes: _limitMinutes,
        days: _selectedDays,
        isNew: false,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _onDelete() async {
    if (widget.existingConfig == null) return;
    await ref.read(timeLimitViewModelProvider.notifier).deleteConfig(widget.existingConfig!.id);
    if (mounted) Navigator.pop(context);
  }

  void _showValidationDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
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
      child: Icon(Icons.edit_rounded, color: AppColors.accent(context), size: 16),
    );
  }
}