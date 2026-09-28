import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'hold_to_confirm.dart';

class PauseScheduleSheet extends StatefulWidget {
  final VoidCallback onResume;
  final Function(int minutes) onPause;
  final VoidCallback? onSpinWheel; // 👈 new — optional, so existing callers still compile
  final bool isPaused;

  const PauseScheduleSheet({
    super.key,
    required this.onResume,
    required this.onPause,
    required this.isPaused,
    this.onSpinWheel,
  });

  static void show(
      BuildContext context, {
        required bool isPaused,
        required VoidCallback onResume,
        required Function(int minutes) onPause,
        VoidCallback? onSpinWheel, // 👈 new
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PauseScheduleSheet(
        isPaused: isPaused,
        onResume: onResume,
        onPause: onPause,
        onSpinWheel: onSpinWheel,
      ),
    );
  }

  @override
  State<PauseScheduleSheet> createState() => _PauseScheduleSheetState();
}

class _PauseScheduleSheetState extends State<PauseScheduleSheet> {
  static const int _pauseMinutes = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 100),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            widget.isPaused ? 'Unpause Blocking' : 'Pause for $_pauseMinutes minutes or Spin?',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isPaused ? 'Reblock Apps?' : 'No Pressure!',
            style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
          ),
          const SizedBox(height: 32),
          if (!widget.isPaused) ...[
            Row( // 👈 new — side by side
              children: [
                Expanded(
                  child: HoldToConfirmButton(
                    color: AppColors.error(context), // 👈 was AppColors.warning(context)
                    fillColor: Color.lerp(AppColors.error(context), Colors.black, 0.25)!, // 👈 darker red for the hold-progress fill
                    textColor: Colors.white, // 👈 was AppColors.warningLight(context)
                    onConfirmed: () {
                      Navigator.pop(context);
                      widget.onPause(_pauseMinutes);
                    },
                  ),
                ),
                if (widget.onSpinWheel != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        widget.onSpinWheel!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent(context), // 👈 was Color(0xFF7DD3B0)
                        foregroundColor: AppColors.accentText(context), // 👈 was Color(0xFF0F4A32)
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const StadiumBorder(),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎡', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Spin',
                              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800,color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            Center(
              child: FractionallySizedBox( // 👈 was SizedBox(width: double.infinity)
                widthFactor: 0.5,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    widget.onResume();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    'BLOCK',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}