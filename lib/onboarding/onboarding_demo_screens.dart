import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausenow/onboarding/widgets/mascot_character.dart';

import '../UI/home/widgets/app_list_sheet.dart';
import '../UI/schedule/schedule_viewmodel.dart';
import '../core/constants/app_constants.dart';
import '../domain/platform/ios_blocking_service.dart';
import '../providers/blocking_service_provider.dart';
import 'onboarding_question_bank.dart';

// ── Demo Explainer Screen ─────────────────────────────
class DemoExplainerScreen extends StatelessWidget {
  final VoidCallback onNext;
  const DemoExplainerScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a0a3d),
                  Color(0xFF16162a),
                  Color(0xFF0a1a2a),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),
                  const MascotCharacter(size: 100),
                  const SizedBox(height: 24),
                  Text(
                    'Almost there!',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'here\'s how pause now works:',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildStep(
                    number: '1',
                    title: 'schedule your blocks',
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    number: '2',
                    title: 'apps get blocked',
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    number: '3',
                    title: 'apps unlock when session ends',
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onNext();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEDB82A),
                        foregroundColor: const Color(0xFF1A1208),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const StadiumBorder(),
                        elevation: 0,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Create Schedule'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEDB82A).withValues(alpha: 0.1),
            border: Border.all(
              color: const Color(0xFFEDB82A).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                color: const Color(0xFFEDB82A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Day Picker

class DemoDaysScreen extends StatefulWidget {
  final List<int> initialDays;
  final Function(List<int> days) onContinue;
  final VoidCallback? onBack;
  final double progress;

  const DemoDaysScreen({
    super.key,
    required this.initialDays,
    required this.onContinue,
    this.onBack,
    required this.progress,
  });

  @override
  State<DemoDaysScreen> createState() => _DemoDaysScreenState();
}

class _DemoDaysScreenState extends State<DemoDaysScreen> {
  late Set<int> _selected;
  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialDays);
  }

  void _toggleDay(int day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(day)) {
        _selected.remove(day);
      } else {
        _selected.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Which days should\nthis schedule run?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least one day',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: _dayNames.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final isSelected = _selected.contains(i);
                return GestureDetector(
                  onTap: () => _toggleDay(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEDB82A).withValues(alpha: 0.1)
                          : const Color(0xFF1E1E35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEDB82A).withValues(alpha: 0.6)
                            : const Color(0xFF2A2A48),
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _dayNames[i],
                          style: GoogleFonts.poppins(
                            color: isSelected ? const Color(0xFFEDB82A) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: isSelected ? const Color(0xFFEDB82A) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFEDB82A) : Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Color(0xFF1A1208), size: 16)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _ContinueButton(
            onTap: _selected.isNotEmpty
                ? () => widget.onContinue(_selected.toList()..sort())
                : null,
          ),
        ],
      ),
    );
  }
}

// App Picker

class DemoAppPickerScreen extends ConsumerStatefulWidget {
  final Function(List<String> apps) onAppsSelected;
  final VoidCallback? onBack;
  final double progress;

  const DemoAppPickerScreen({
    super.key,
    required this.onAppsSelected,
    this.onBack,
    required this.progress,
  });

  @override
  ConsumerState<DemoAppPickerScreen> createState() => _DemoAppPickerScreenState();
}

class _DemoAppPickerScreenState extends ConsumerState<DemoAppPickerScreen> {
  bool _isPicking = false;

  Future<void> _openRealPicker() async {
    setState(() => _isPicking = true);
    try {
      if (Platform.isIOS) {
        final service = ref.read(blockingServiceProvider) as IOSBlockingService;
        final count = await service.showAppPicker(
          blockingMode: AppConstants.blockingTypeSpecificApps,
        );
        final selectedCount = count ?? 0;

        if (selectedCount == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select at least 1 app to block')),
            );
          }
          return;
        }

        // 👇 cap at 3, even if the picker somehow returned more
        final cappedCount = selectedCount > 3 ? 3 : selectedCount;
        final placeholders = List.generate(cappedCount, (i) => 'ios_app_$i');
        widget.onAppsSelected(placeholders);
      } else {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useRootNavigator: true,
          builder: (_) => AppListSheet(
            isBlockList: true,
            initialApps: const [],
            onSave: (apps) {
              if (apps.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least 1 app to block')),
                );
                return;
              }
              final capped = apps.length > 3 ? apps.sublist(0, 3) : apps;
              widget.onAppsSelected(capped);
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ demo app picker error: $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Which apps do you\nwant to block?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick the apps for this schedule',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Row(
                      children: [
                        Text(
                          'Select Apps',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _isPicking ? null : _openRealPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: _isPicking
                                ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : Text(
                              'Add',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.06), height: 0.5),
                  Expanded(
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _fakeRow('📚', 'All Apps & Categories'),
                        _fakeRow('💬', 'Social'),
                        _fakeRow('🎮', 'Games'),
                        _fakeRow('🍿', 'Entertainment'),
                        _fakeRow('🎨', 'Creativity'),
                        _fakeRow('🌍', 'Education'),
                        _fakeRow('🚴', 'Health & Fitness'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_upward_rounded, color: Colors.white.withValues(alpha: 0.4), size: 16),
              const SizedBox(width: 6),
              Text(
                'Tap Add',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // 👈 new
          Center( // 👈 new
            child: GestureDetector(
              onTap: () => widget.onAppsSelected([]), // 👈 skip — proceeds with empty list, no validation
              child: Text(
                'Skip for now (debug)',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _fakeRow(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
          ),
          const SizedBox(width: 14),
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }
}

// Bar chart

class DemoComparisonScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final double progress;
  final TimeOfDay scheduleStart;
  final TimeOfDay scheduleEnd;
  final List<int> scheduleDays;
  final List<String> blockedApps;

  const DemoComparisonScreen({
    super.key,
    required this.onNext,
    this.onBack,
    required this.progress,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.scheduleDays,
    required this.blockedApps,
  });

  @override
  ConsumerState<DemoComparisonScreen> createState() => _DemoComparisonScreenState();
}

class _DemoComparisonScreenState extends ConsumerState<DemoComparisonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _titleFade;
  late Animation<double> _cardFade;
  late Animation<double> _withoutBarGrow;
  late Animation<double> _withBarGrow;
  late Animation<double> _subtitleFade;
  late Animation<double> _buttonFade;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _titleFade = _interval(0.0, 0.15);
    _cardFade = _interval(0.15, 0.3);
    _withoutBarGrow = _interval(0.35, 0.6);
    _withBarGrow = _interval(0.55, 0.85);
    _subtitleFade = _interval(0.8, 0.95);
    _buttonFade = _interval(0.9, 1.0);
    _ctrl.forward();
  }

  Animation<double> _interval(double start, double end) {
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _createScheduleAndContinue() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(scheduleViewModelProvider.notifier).saveSchedule(
        name: 'Blocked Apps',
        startTime: _fmt(widget.scheduleStart),
        endTime: _fmt(widget.scheduleEnd),
        days: widget.scheduleDays,
        blockingType: AppConstants.blockingTypeSpecificApps,
        blockedApps: widget.blockedApps,
        allowedApps: const [],
      );
    } catch (e) {
      debugPrint('❌ demo schedule creation error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _titleFade,
                child: Text(
                  'Become 5x more productive with pause now',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Transform.scale(
                  scale: 1.0, // 👈 adjust this one number — 1.0 = current size, 0.75 = 75%, 0.5 = half size, etc.
                  child: SizedBox(
                    height: 320, // keep whatever height you were using before scaling
                    child: Row(
                      children: [
                        Expanded(
                          child: FadeTransition(
                            opacity: _cardFade,
                            child: _buildCard(
                              label: 'Without pause now',
                              heightFraction: 0.2 * _withoutBarGrow.value,
                              valueLabel: '20%',
                              filled: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: FadeTransition(
                            opacity: _cardFade,
                            child: _buildCard(
                              label: 'With pause now',
                              heightFraction: 1.0 * _withBarGrow.value,
                              valueLabel: '5x',
                              filled: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _subtitleFade,
                child: Text(
                  'pause now makes it easy and holds you accountable.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

              const Spacer(),

              FadeTransition(
                opacity: _buttonFade,
                child: _ContinueButton(
                  onTap: _isSaving ? null : _createScheduleAndContinue,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String label,
    required double heightFraction,
    required String valueLabel,
    required bool filled,
  }) {
    return ClipRRect( // 👈 new — clips the fill to the card's rounded corners when it's flush against the edges
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E35),

        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding( // 👈 padding now ONLY wraps the label
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = constraints.maxHeight;
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: maxHeight * heightFraction.clamp(0.0, 1.0),
                        width: double.infinity, // 👈 no padding above/around this — fills edge to edge
                        color: filled
                            ? const Color(0xFFEDB82A)
                            : Colors.white.withValues(alpha: 0.12),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              valueLabel,
                              style: GoogleFonts.poppins(
                                color: filled ? const Color(0xFF1A1208) : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// ── Shared continue button ────────────────────────────

class _ContinueButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  const _ContinueButton({this.onTap, this.label = 'Continue'});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onTap != null ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEDB82A),
            foregroundColor: const Color(0xFF1A1208),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: const StadiumBorder(),
            disabledBackgroundColor: const Color(0xFFEDB82A).withValues(alpha: 0.4),
            textStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}