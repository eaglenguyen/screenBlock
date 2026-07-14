import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../UI/schedule/widgets/hold_to_confirm.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/time_limit_config.dart';

class TimeLimitOptionsSheet extends StatefulWidget {
  final TimeLimitConfig config;
  final bool isLimitReached; // pass in current status
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TimeLimitOptionsSheet({
    super.key,
    required this.config,
    required this.isLimitReached,
    required this.onEdit,
    required this.onDelete,
  });

  static void show(
      BuildContext context, {
        required TimeLimitConfig config,
        required bool isLimitReached,
        required VoidCallback onEdit,
        required VoidCallback onDelete,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true, // 👈 add this

      builder: (_) => TimeLimitOptionsSheet(
        config: config,
        isLimitReached: isLimitReached,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<TimeLimitOptionsSheet> createState() => _TimeLimitOptionsSheetState();
}

class _TimeLimitOptionsSheetState extends State<TimeLimitOptionsSheet>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
  }




  @override
  Widget build(BuildContext context) {
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

              // ── icon + labels ──
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shield_rounded, color: AppColors.gold(context), size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                'Time Limit',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gold(context),
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

              // ── status circle ──
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundCard(context),
                  border: Border.all(
                    color: widget.isLimitReached
                        ? AppColors.error(context).withValues(alpha: 0.3)
                        : AppColors.gold(context).withValues(alpha: 0.25),
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isLimitReached ? Icons.block_rounded : Icons.check_circle_rounded,
                      color: widget.isLimitReached ? AppColors.error(context) : const Color(0xFF4CAF50),
                      size: 56,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.isLimitReached ? 'Blocked' : 'Monitoring',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: widget.isLimitReached ? AppColors.error(context) : const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isLimitReached ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary(context),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isLimitReached ? 'Limit has been reached' : 'Limit is not reached',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
                  ),
                ],
              ),

              const Spacer(),


              // ── Edit button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onEdit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold(context),
                    foregroundColor: AppColors.goldText(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    textStyle: AppTextStyles.labelLarge,
                  ),
                  child: const Text('Edit Limit'),
                ),
              ),
              const SizedBox(height: 15),

              // ── hold-to-delete ──
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