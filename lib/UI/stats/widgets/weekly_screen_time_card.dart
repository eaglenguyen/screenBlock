import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _weekDays = _buildWeekDays(_selectedDay);
    _fetchWeek();

    // 👇 re-fetch once more after giving the trigger view time to compute and write
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _fetchWeek();
    });
  }

  List<DateTime> _buildWeekDays(DateTime anyDayInWeek) {
    // Dart's DateTime.weekday: Mon=1...Sun=7 → convert so Sunday is day 0 of our week
    final daysSinceSunday = anyDayInWeek.weekday % 7; // Sun(7)->0, Mon(1)->1, ... Sat(6)->6
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
        child: CircularProgressIndicator(color: AppColors.gold(context)),
      );
    }

    final maxSeconds = _weekDays
        .map(_secondsFor)
        .fold<double>(0, (max, v) => v > max ? v : max);

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Stack(
      children: [
        Container(
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
                        : () => setState(() => _selectedDay = day),
                    child: Column(
                      children: [
                        Text(
                          dayLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.gold(context)
                                : AppColors.textSecondary(context).withValues(alpha: isFuture ? 0.3 : 0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.gold(context)
                                : AppColors.backgroundSubtle(context),
                            border: isFuture
                                ? Border.all(color: AppColors.border(context), width: 1)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 12,
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

              // bar chart
              // SizedBox(
              //   height: 80,
              //   child: Row(
              //     crossAxisAlignment: CrossAxisAlignment.end,
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: List.generate(7, (i) {
              //       final day = _weekDays[i];
              //       final isSelected = _isSameDay(day, _selectedDay);
              //       final isFuture = _isFuture(day);
              //       final seconds = _secondsFor(day);
              //       final heightFraction = maxSeconds > 0 ? (seconds / maxSeconds).clamp(0.05, 1.0) : 0.05;
              //
              //       return AnimatedContainer(
              //         duration: const Duration(milliseconds: 200),
              //         width: 20,
              //         height: 80 * (isFuture ? 0.05 : heightFraction),
              //         decoration: BoxDecoration(
              //           color: isSelected
              //               ? AppColors.gold(context)
              //               : AppColors.backgroundSubtle(context),
              //           borderRadius: BorderRadius.circular(4),
              //         ),
              //       );
              //     }),
              //   ),
              // ),

              const SizedBox(height: 20),
              Divider(color: AppColors.border(context), height: 1),
              const SizedBox(height: 20),

              // selected day total
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _formatSelectedDayLabel(),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => _openDetailForSelectedDay(context),
                  child: Text(
                    'See screentime breakdown →',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gold(context),
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
    final weekdayIndex = _selectedDay.weekday % 7; // Mon=1..Sun=7 -> Sun=0
    return '${weekdays[weekdayIndex]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
  }

  void _openDetailForSelectedDay(BuildContext context) {
    // opens the native per-app breakdown for _selectedDay specifically —
    // requires passing the selected date to the native report view
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: UiKitView(
          viewType: 'com.eagle.pausenow/screen_time_report_view',
          creationParams: {'date': _dateKey(_selectedDay)}, // 👈 new — tells native which day to show
          creationParamsCodec: const StandardMessageCodec(),
        ),
      ),
    );
  }
}