import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../UI/schedule/widgets/hold_to_confirm.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/time_limit_config.dart';
import '../../../domain/platform/android_blocking_service.dart';
import '../../../providers/blocking_service_provider.dart';

class TimeLimitOptionsSheet extends ConsumerStatefulWidget {
  final TimeLimitConfig config;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TimeLimitOptionsSheet({
    super.key,
    required this.config,
    required this.onEdit,
    required this.onDelete,
  });

  static void show(
      BuildContext context, {
        required TimeLimitConfig config,
        required VoidCallback onEdit,
        required VoidCallback onDelete,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => TimeLimitOptionsSheet(
        config: config,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  ConsumerState<TimeLimitOptionsSheet> createState() => _TimeLimitOptionsSheetState();
}

class _TimeLimitOptionsSheetState extends ConsumerState<TimeLimitOptionsSheet> {
  Timer? _refreshTimer;
  int _usedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadUsage();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadUsage());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    final service = ref.read(blockingServiceProvider);
    if (service is! AndroidBlockingService) return;

    int total = 0;
    for (final pkg in widget.config.packageNames) {
      total += await service.getUsedMinutesToday(pkg);
    }
    if (mounted) setState(() => _usedMinutes = total);
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
    final showMeter = Platform.isAndroid;
    final isLimitReached = showMeter && _usedMinutes >= widget.config.limitMinutes; // 👈 derived, not passed in
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shield_rounded, color: AppColors.accent(context), size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                'Time Limit',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.accent(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.config.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundCard(context),
                  border: Border.all(
                    color: isLimitReached
                        ? AppColors.error(context).withValues(alpha: 0.3)
                        : AppColors.accent(context).withValues(alpha: 0.25),
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLimitReached ? Icons.block_rounded : Icons.check_circle_rounded,
                      color: isLimitReached ? AppColors.error(context) : AppColors.success(context),
                      size: 56,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isLimitReached ? 'Blocked' : 'Monitoring',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isLimitReached ? AppColors.error(context) : AppColors.success(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showMeter) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_formatMinutes(_usedMinutes)} / ${_formatMinutes(widget.config.limitMinutes)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isLimitReached ? AppColors.error(context) : AppColors.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLimitReached ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary(context),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isLimitReached ? 'Limit has been reached' : 'Limit is not reached',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onEdit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.accentText(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    textStyle: AppTextStyles.labelLarge,
                  ),
                  child: const Text('Edit Limit'),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: HoldToConfirmButton(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.4),
                  fillColor: Color.lerp(AppColors.textSecondary(context), Colors.black, 0.3)!,
                  textColor: Colors.white,
                  label: 'Hold to delete',
                  holdingLabel: 'Keep holding...',
                  doneLabel: 'Deleted',
                  onConfirmed: () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}