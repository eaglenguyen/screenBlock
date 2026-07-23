import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../stats_viewmodel.dart';

class WeeklyScreenTimeCardAndroid extends ConsumerStatefulWidget {
  final ValueChanged<DateTime>? onDaySelected;

  const WeeklyScreenTimeCardAndroid({super.key, this.onDaySelected});

  @override
  ConsumerState<WeeklyScreenTimeCardAndroid> createState() => _WeeklyScreenTimeCardAndroidState();
}

class _WeeklyScreenTimeCardAndroidState extends ConsumerState<WeeklyScreenTimeCardAndroid> {
  Map<String, double> _weekData = {};
  bool _isLoading = true;
  bool _hasPermission = true; // 👈 new
  late DateTime _selectedDay;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _weekDays = _buildWeekDays(_selectedDay);
    _fetchWeek();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDaySelected?.call(_selectedDay);
    });
  }

  List<DateTime> _buildWeekDays(DateTime anyDayInWeek) {
    final daysSinceSunday = anyDayInWeek.weekday % 7;
    final sunday = anyDayInWeek.subtract(Duration(days: daysSinceSunday));
    return List.generate(7, (i) => DateTime(sunday.year, sunday.month, sunday.day + i));
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _fetchWeek() async {
    final notifier = ref.read(statsViewModelProvider.notifier);

    // check permission once, up front — don't let 7 individual calls each discover it's missing
    final hasPermission = await notifier.hasUsagePermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
      return; // bail — don't loop through 7 days that would all fail the same way
    }

    final Map<String, double> result = {};
    for (final day in _weekDays) {
      if (_isFuture(day)) continue;
      final seconds = await notifier.getTotalSecondsForDay(day);
      result[_dateKey(day)] = seconds;
    }

    if (mounted) {
      setState(() {
        _weekData = result;
        _isLoading = false;
      });
    }
  }

  double _secondsFor(DateTime day) => _weekData[_dateKey(day)] ?? 0;

  String _formatDuration(double seconds) {
    final totalMinutes = (seconds / 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  bool _isFuture(DateTime day) {
    final today = DateTime.now();
    final dayOnly = DateTime(day.year, day.month, day.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    return dayOnly.isAfter(todayOnly);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatSelectedDayLabel() {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    const weekdays = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    final weekdayIndex = _selectedDay.weekday % 7;
    return '${weekdays[weekdayIndex]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: AppColors.gold(context)),
      );
    }

    // New
    if (!_hasPermission) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary(context), size: 36),
            const SizedBox(height: 12),
            Text(
              'Usage access required',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Grant usage access to see your weekly screen time',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await ref.read(statsViewModelProvider.notifier).requestUsagePermission();
                // re-check once they return from Settings
                setState(() => _isLoading = true);
                _fetchWeek();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold(context),
                foregroundColor: AppColors.goldText(context),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    final maxSeconds = _weekDays
        .map(_secondsFor)
        .fold<double>(0, (max, v) => v > max ? v : max);

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary(context))),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = _weekDays[i];
              final isSelected = _isSameDay(day, _selectedDay);
              final isFuture = _isFuture(day);

              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () {
                  setState(() => _selectedDay = day);
                  widget.onDaySelected?.call(day);
                },
                child: Column(
                  children: [
                    Text(
                      dayLabels[i],
                      style: AppTextStyles.bodySmall.copyWith( // 👈 was fontSize: 10 — now 11 via bodySmall
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.gold(context)
                            : AppColors.textSecondary(context).withValues(alpha: isFuture ? 0.3 : 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.gold(context) : AppColors.backgroundSubtle(context),
                        border: isFuture ? Border.all(color: AppColors.border(context), width: 1) : null,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: AppTextStyles.bodySmall.copyWith( // 👈 was fontSize: 12 — now 11
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.goldText(context)
                                : AppColors.textSecondary(context).withValues(alpha: isFuture ? 0.3 : 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = _weekDays[i];
                final isSelected = _isSameDay(day, _selectedDay);
                final isFuture = _isFuture(day);
                final seconds = _secondsFor(day);
                final heightFraction = maxSeconds > 0 ? (seconds / maxSeconds).clamp(0.05, 1.0) : 0.05;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 80 * (isFuture ? 0.05 : heightFraction),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold(context) : AppColors.backgroundSubtle(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.border(context), height: 1),
          const SizedBox(height: 20),

          Center(
            child: Column(
              children: [
                Text(
                  _formatDuration(_secondsFor(_selectedDay)),
                  style: AppTextStyles.displayMedium.copyWith( // 👈 was fontSize: 38 — now 32
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatSelectedDayLabel(),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)), // already 11
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}