import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pausenow/core/theme/lipped_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class WeeklyScreenTimeCard extends StatefulWidget {
  const WeeklyScreenTimeCard({super.key});

  @override
  State<WeeklyScreenTimeCard> createState() => _WeeklyScreenTimeCardState();
}

class _WeeklyScreenTimeCardState extends State<WeeklyScreenTimeCard> {
  Map<String, double> _weekData = {}; // 'yyyy-MM-dd' → seconds
  bool _isLoading = true;
  late DateTime _selectedDay;
  late List<DateTime> _weekDays; // Sun -> Sat
  bool _showScreenTime = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _weekDays = _buildWeekDays(_selectedDay);
    _fetchWeek();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _fetchWeek();
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
    if (!Platform.isIOS) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final result = await const MethodChannel('com.eagle.pausenow/ios_blocking')
          .invokeMethod<Map>('getWeeklyScreenTime');
      setState(() {
        _weekData = result?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ?? {};
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ getWeeklyScreenTime error: $e');
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: AppColors.accent(context)),
      );
    }

    final maxSeconds = _weekDays
        .map(_secondsFor)
        .fold<double>(0, (max, v) => v > max ? v : max);

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Stack(
      children: [
        LippedCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('This Week', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary(context))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent(context).withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'Beta',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              // day chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final day = _weekDays[i];
                  final isSelected = _isSameDay(day, _selectedDay);
                  final isFuture = _isFuture(day);

                  return GestureDetector(
                    onTap: isFuture
                        ? null
                        : () => setState(() {
                      _selectedDay = day;
                      _showScreenTime = false;
                    }),
                    child: Column(
                      children: [
                        Text(
                          dayLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.accent(context)
                                : AppColors.textSecondary(context).withValues(alpha: isFuture ? 0.3 : 0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.accent(context)
                                : AppColors.backgroundSubtle(context),
                            border: isFuture
                                ? Border.all(color: AppColors.border(context), width: 1)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.accentText(context)
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
              Divider(color: AppColors.border(context), height: 1),
              const SizedBox(height: 20),

              _buildScreenTimeReveal(context),

              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _formatSelectedDayLabel(),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => _openDetailForSelectedDay(context),
                  child: Text(
                    'Full breakdown →',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.accent(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 1,
          height: 1,
          child: UiKitView(
            viewType: 'com.eagle.pausenow/weekly_data_trigger_view',
          ),
        ),
      ],
    );
  }

  String _formatSelectedDayLabel() {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    const weekdays = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    final weekdayIndex = _selectedDay.weekday % 7;
    return '${weekdays[weekdayIndex]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
  }

  void _openDetailForSelectedDay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: UiKitView(
          viewType: 'com.eagle.pausenow/screen_time_report_view',
          creationParams: {'date': _dateKey(_selectedDay)},
          creationParamsCodec: const StandardMessageCodec(),
        ),
      ),
    );
  }

  Widget _buildScreenTimeReveal(BuildContext context) {
    if (!_showScreenTime) {
      return Center(
        child: Column(
          children: [
            Text(
              '? ? ?',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.textSecondary(context),
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showScreenTime = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.textPrimary(context).withValues(alpha: 0.4), width: 0.9),
                ),
                child: Text(
                  "Show screen time",
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: UiKitView(
        key: ValueKey(_dateKey(_selectedDay)),
        viewType: 'com.eagle.pausenow/compact_screen_time_view',
        creationParams: {'date': _dateKey(_selectedDay)},
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}