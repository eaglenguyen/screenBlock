import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'hold_to_confirm.dart';

class PauseScheduleSheet extends StatefulWidget {
  final VoidCallback onResume; // resume immediately
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
  double _selectedMinutes = 5;

  String get _formattedDuration {
    final mins = _selectedMinutes.round();
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).padding.bottom + 100,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            widget.isPaused ? 'Schedule Paused' : 'Pause Blocking',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isPaused
                ? 'Resume Blocking?'
                : 'How long do you want to pause?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          if (!widget.isPaused) ...[
            // duration display
            Text(
              _formattedDuration,
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontSize: 52,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 8),


            // slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.orange,
                inactiveTrackColor: Colors.orange.withValues(alpha: 0.15),
                thumbColor: Colors.orange,
                overlayColor: Colors.orange.withValues(alpha: 0.15),
                thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 10),
                trackHeight: 5,
              ),
              child: Slider(
                value: _selectedMinutes,
                min: 3,
                max: 30,
                divisions: 27,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMinutes = val);
                },
              ),
            ),

            // min/max labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('3m',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      )),
                  Text('30m',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // pause button
            SizedBox(
              width: double.infinity,
              child: HoldToConfirmButton(
                onConfirmed: () {
                  Navigator.pop(context);
                  widget.onPause(_selectedMinutes.round());
                },
              ),
            ),
          ] else ...[
            // resume button when already paused
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onResume();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6666A3),
                  foregroundColor: const Color(0xFF1A1208),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Yes, Block My Apps'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}