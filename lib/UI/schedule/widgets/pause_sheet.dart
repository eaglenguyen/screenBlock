import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'hold_to_confirm.dart';

class PauseScheduleSheet extends StatefulWidget {
  final VoidCallback onResume;
  final Function(int minutes) onPause;
  final bool isPaused;

  const PauseScheduleSheet({
    super.key,
    required this.onResume,
    required this.onPause,
    required this.isPaused,
  });

  static void show(
      BuildContext context, {
        required bool isPaused,
        required VoidCallback onResume,
        required Function(int minutes) onPause,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PauseScheduleSheet(
        isPaused: isPaused,
        onResume: onResume,
        onPause: onPause,
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
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).padding.bottom + 100,
      ),
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
            widget.isPaused ? 'Unpause Blocking' : 'Pause for $_pauseMinutes minutes?',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary(context)),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isPaused
                ? 'Reblock Apps?'
                : 'Make it quick!',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          if (!widget.isPaused) ...[
            Text(
              '${_pauseMinutes}m',
              style: GoogleFonts.poppins(
                color: AppColors.warning(context),
                fontSize: 52,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: HoldToConfirmButton(
                color: AppColors.warning(context),
                fillColor: AppColors.warningDark(context),
                textColor: AppColors.warningLight(context),
                onConfirmed: () {
                  Navigator.pop(context);
                  widget.onPause(_pauseMinutes);
                },
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onResume();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning(context),
                  foregroundColor: AppColors.accentPeachText(context),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('BLOCK'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}