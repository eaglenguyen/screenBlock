import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/hivebox_names.dart';

class CheckInSliderScreen extends StatefulWidget {
  final String question;
  final List<String> emojis;
  final List<String> labels;
  final VoidCallback onContinue;
  final ValueChanged<int>? onAnswered;

  const CheckInSliderScreen({
    super.key,
    required this.question,
    required this.emojis,
    required this.labels,
    required this.onContinue,
    this.onAnswered,
  });

  @override
  State<CheckInSliderScreen> createState() => _CheckInSliderScreenState();
}

class _CheckInSliderScreenState extends State<CheckInSliderScreen> {
  late double _value;

  @override
  void initState() {
    super.initState();
    // default to a middle-leaning positive option, matching the screenshot ("good")
    _value = 2;
  }

  @override
  Widget build(BuildContext context) {
    final index = _value.round();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A7BB5), Color(0xFF2C4D7A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Text(
                  widget.question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  widget.emojis[index],
                  style: const TextStyle(fontSize: 72),
                ),
                const SizedBox(height: 32),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.15),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _value,
                    min: 0,
                    max: (widget.labels.length - 1).toDouble(),
                    divisions: widget.labels.length - 1,
                    onChanged: (v) => setState(() => _value = v),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.labels[index],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onAnswered?.call(index);
                      widget.onContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2C4D7A),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class CheckInFlow {
  static const _lastShownKey = 'checkInLastShownDate';

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static bool _hasShownToday() {
    final box = Hive.box(HiveBoxNames.settings);
    final lastShown = box.get(_lastShownKey) as String?;
    if (lastShown == null) return false;
    return lastShown == _todayKey();
  }

  static Future<void> _markShownToday() async {
    final box = Hive.box(HiveBoxNames.settings);
    await box.put(_lastShownKey, _todayKey());
  }

  static void show(BuildContext context, {required VoidCallback onComplete}) {
    if (_hasShownToday()) {
      debugPrint('📋 check-in already shown today — skipping');
      onComplete(); // 👈 still runs — keeps clearPendingCheckIn() working correctly
      return;
    }


    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CheckInSliderScreen(
          question: 'how are you\nfeeling today?',
          emojis: const ['😔', '😐', '🙂', '😄'],
          labels: const ['bad', 'okay', 'good', 'great'],
          onAnswered: (index) {
            // 👇 persist mood answer here, e.g. via a repository call
          },
          onContinue: () {
            Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => CheckInSliderScreen(
                  question: 'how productive\nwere you today?',
                  emojis: const ['😓', '🙂', '💪', '🔥'],
                  labels: const [
                    'struggled today',
                    'made some progress',
                    'mostly productive',
                    'busy all day',
                  ],
                  onAnswered: (index) {
                    // 👇 persist productivity answer here
                  },
                  onContinue: () async {
                    await _markShownToday(); // 👈 moved here — only counts once both screens are done
                    Navigator.of(context, rootNavigator: true).pop();
                    onComplete();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}