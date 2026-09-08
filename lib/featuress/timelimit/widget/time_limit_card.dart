import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../UI/schedule/widgets/app_icon_stack.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/time_limit_config.dart';
import '../../../domain/platform/android_blocking_service.dart';
import '../../../providers/blocking_service_provider.dart';

class TimeLimitCard extends ConsumerStatefulWidget {
  final TimeLimitConfig config;
  final VoidCallback? onTap;
  const TimeLimitCard({
    super.key,
    required this.config,
    required this.onTap,
  });

  @override
  ConsumerState<TimeLimitCard> createState() => _TimeLimitCardState();
}

class _TimeLimitCardState extends ConsumerState<TimeLimitCard> {
  Timer? _refreshTimer;
  int _usedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadUsage();
    if (Platform.isIOS) {
      // 👈 new — give the report extension a moment to compute after the trigger renders
      Future.delayed(const Duration(seconds: 2), _loadUsage);
    }
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadUsage());
  }

  @override
  void didUpdateWidget(TimeLimitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.packageNames.join(',') != widget.config.packageNames.join(',') ||
        oldWidget.config.limitMinutes != widget.config.limitMinutes) {
      _loadUsage();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    final service = ref.read(blockingServiceProvider);
    if (service is! AndroidBlockingService) return; // 👈 iOS no longer attempts a fetch at all
    int total = 0;
    for (final pkg in widget.config.packageNames) {
      total += await service.getUsedMinutesToday(pkg);
    }
    if (mounted) setState(() => _usedMinutes = total);
  }

  String get _daysLabel {
    final days = widget.config.days;
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && !days.contains(5) && !days.contains(6)) return 'Weekdays';
    if (days.length == 2 && days.contains(5) && days.contains(6)) return 'Weekends';
    return 'Custom';
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final showMeter = Platform.isAndroid; // 👈 was true for both platforms
    final isOverLimit = showMeter && _usedMinutes >= widget.config.limitMinutes;
    final progress = showMeter ? (_usedMinutes / widget.config.limitMinutes).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconStack(
                  packageNames: widget.config.packageNames,
                  iosStorageKey: 'timeLimitApps_${widget.config.id}',
                  refreshToken: widget.config.updatedAt.millisecondsSinceEpoch,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.config.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatMinutes(widget.config.limitMinutes)}/day · ${widget.config.packageNames.length} apps · $_daysLabel',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showMeter) // 👈 only shown on Android now
                  Text(
                    '${_formatMinutes(_usedMinutes)} / ${_formatMinutes(widget.config.limitMinutes)}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isOverLimit ? AppColors.error(context) : AppColors.textPrimary(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (showMeter) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loadUsage,
                    child: Icon(Icons.refresh_rounded, size: 16, color: AppColors.textSecondary(context)),
                  ),
                ],
              ],
            ),
            if (showMeter) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.backgroundSubtle(context),
                  valueColor: AlwaysStoppedAnimation(
                    isOverLimit ? AppColors.error(context) : AppColors.accent(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}