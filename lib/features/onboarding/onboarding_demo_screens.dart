import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/platform/ios_blocking_service.dart';
import '../../providers/blocking_service_provider.dart';
import '../home/home_viewmodel.dart';
import '../home/schedule/schedule_viewmodel.dart';
import '../home/widgets/app_list_sheet.dart';

// ── Demo screens container ────────────────────────────

class OnboardingDemoFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingDemoFlow({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingDemoFlow> createState() =>
      _OnboardingDemoFlowState();
}

class _OnboardingDemoFlowState
    extends ConsumerState<OnboardingDemoFlow> {
  int _step = 0;
  String _selectedDisconnectTime = '';
  bool _scheduleCreated = false;

  void _next() {
    HapticFeedback.lightImpact();
    setState(() => _step++);
  }

  void _onDisconnectSelected(String time) {
    setState(() {
      _selectedDisconnectTime = time;
      _step++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _DemoPickAppScreen(
          key: const ValueKey('demo1'),
          onNext: _next,
        );
      case 1:
        return _DemoBoldStatementScreen(
          key: const ValueKey('demo2'),
          onNext: _next,
        );
      case 2:
        return _DemoDisconnectScreen(
          key: const ValueKey('demo3'),
          onSelected: _onDisconnectSelected,
        );
      case 3:
        return _DemoSchedulePreviewScreen(
          key: const ValueKey('demo4'),
          disconnectTime: _selectedDisconnectTime,
          onNext: (created) {
            setState(() => _scheduleCreated = created);
            _next();
          },
        );
      case 4:
        return _DemoScheduleTabScreen(
          key: const ValueKey('demo5'),
          onNext: _next,
        );
      case 5:
        return _DemoBlockingScreen(
          key: const ValueKey('demo6'),
          onNext: _next,
        );
      case 6:
        return _DemoXpScreen(
          key: const ValueKey('demo7'),
          onNext: widget.onComplete,
        );
      default:
        widget.onComplete();
        return const SizedBox.shrink();
    }
  }
}

// ── Demo Screen 1 — Pick distracting app ─────────────

class _DemoPickAppScreen extends ConsumerWidget {
  final VoidCallback onNext;

  const _DemoPickAppScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DemoShell(
      child: Column(
        children: [
          const Spacer(flex: 2),
          const SizedBox(height: 32),
          Text(
            'Pick your most\ndistracting app',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "We'll help you limit it",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 17,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 3),
          _DemoButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Choose an App',
            onTap: () => _openAppPicker(context, ref),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _openAppPicker(BuildContext context, WidgetRef ref) {
    if (Platform.isIOS) {
      _showIOSPicker(context, ref);
    } else {
      _showAndroidPicker(context, ref);
    }
  }

  void _showIOSPicker(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(blockingServiceProvider)
      as IOSBlockingService;
      final count = await service.showAppPicker(
        blockingMode: AppConstants.blockingTypeSpecificApps,
      );
      if ((count ?? 0) > 0) {
        final placeholders = List.generate(count!, (i) => 'ios_app_$i');
        ref.read(homeViewModelProvider.notifier)
            .setBlockedApps(placeholders);
        onNext(); // 👈 advance after picking
      }
    } catch (e) {
      debugPrint('❌ iOS app picker error: $e');
    }
  }

  void _showAndroidPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => AppListSheet(
        isBlockList: true,
        initialApps: const [],
        onSave: (apps) {
          ref.read(homeViewModelProvider.notifier)
              .setBlockedApps(apps);
          onNext(); // 👈 advance after saving
        },
      ),
    );
  }
}

// ── Demo Screen 2 — Bold statement ───────────────────

class _DemoBoldStatementScreen extends StatelessWidget {
  final VoidCallback onNext;

  const _DemoBoldStatementScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _DemoShell(
      child: Column(
        children: [
          const Spacer(flex: 2),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.25,
              ),
              children: [
                const TextSpan(text: "Let's pick a peak\nfocus time to block "),
                TextSpan(
                  text: 'ALL',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEDB82A),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const TextSpan(text: '* of\nyour apps.'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '*Except for the productive ones 🧡',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFFEDB82A).withValues(alpha: 0.8),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Spacer(flex: 3),
          _DemoButton(
            label: 'Continue',
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Demo Screen 3 — When to disconnect ───────────────

class _DemoDisconnectScreen extends StatefulWidget {
  final Function(String time) onSelected;

  const _DemoDisconnectScreen({super.key, required this.onSelected});

  @override
  State<_DemoDisconnectScreen> createState() => _DemoDisconnectScreenState();
}

class _DemoDisconnectScreenState extends State<_DemoDisconnectScreen> {
  String? _selected;

  final List<Map<String, String>> _options = [
    {'emoji': '🌅', 'label': 'In the morning', 'time': 'morning'},
    {'emoji': '🛌', 'label': 'Before bed', 'time': 'bed'},
    {'emoji': '💼', 'label': 'At work', 'time': 'work'},
  ];

  @override
  Widget build(BuildContext context) {
    return _DemoShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          Text(
            'When do you want\nto disconnect?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          ..._options.map((opt) {
            final isSelected = _selected == opt['time'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selected = opt['time']);
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    () => widget.onSelected(opt['time']!),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEDB82A).withValues(alpha: 0.1)
                        : const Color(0xFF1E1E35),
                    borderRadius: BorderRadius.circular(16),
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
                        opt['emoji']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        opt['label']!,
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? const Color(0xFFEDB82A)
                              : Colors.white,
                          fontSize: 17,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDB82A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Color(0xFF1A1208),
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }
}

// ── Demo Screen 4 — Schedule preview ─────────────────

class _DemoSchedulePreviewScreen extends ConsumerWidget {
  final String disconnectTime;
  final Function(bool created) onNext;

  const _DemoSchedulePreviewScreen({
    super.key,
    required this.disconnectTime,
    required this.onNext,
  });

  String get _scheduleName {
    switch (disconnectTime) {
      case 'morning': return 'Morning Focus';
      case 'bed': return 'Night Mode';
      case 'work': return 'Work Hours';
      default: return 'Focus Time';
    }
  }

  String get _emoji {
    switch (disconnectTime) {
      case 'morning': return '🌅';
      case 'bed': return '🌙';
      case 'work': return '💼';
      default: return '⏰';
    }
  }

  String get _startTime {
    switch (disconnectTime) {
      case 'morning': return '06:00';
      case 'bed': return '22:00';
      case 'work': return '09:00';
      default: return '09:00';
    }
  }

  String get _endTime {
    switch (disconnectTime) {
      case 'morning': return '09:00';
      case 'bed': return '05:00';
      case 'work': return '17:00';
      default: return '17:00';
    }
  }

  String get _startDisplay {
    switch (disconnectTime) {
      case 'morning': return '6:00 AM';
      case 'bed': return '10:00 PM';
      case 'work': return '9:00 AM';
      default: return '9:00 AM';
    }
  }

  String get _endDisplay {
    switch (disconnectTime) {
      case 'morning': return '9:00 AM';
      case 'bed': return '5:00 AM';
      case 'work': return '5:00 PM';
      default: return '5:00 PM';
    }
  }

  List<int> get _days {
    switch (disconnectTime) {
      case 'morning': return [0, 1, 2, 3, 4, 5, 6];
      case 'bed': return [0, 1, 2, 3, 4, 5, 6];
      case 'work': return [0, 1, 2, 3, 4];
      default: return [0, 1, 2, 3, 4];
    }
  }

  Future<void> _createSchedule(WidgetRef ref) async {
    try {
      await ref
          .read(scheduleViewModelProvider.notifier)
          .saveSchedule(
        name: _scheduleName,
        startTime: _startTime,
        endTime: _endTime,
        days: _days,
        blockingType: AppConstants.blockingTypeSpecificApps,
        blockedApps: ref.read(homeViewModelProvider).blockedApps,
        allowedApps: const [],
      );
      debugPrint('📅 Demo schedule created: $_scheduleName');
    } catch (e) {
      debugPrint('❌ Demo schedule creation error: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return _DemoShell(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            "Here's your\nscheduled session",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),

          // schedule card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFEDB82A).withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // schedule name
                Row(
                  children: [
                    Text(_emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(
                      _scheduleName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF2A2A48), thickness: 0.5),
                const SizedBox(height: 16),

                // start/end times
                _timeRow('Starts', _startDisplay),
                const SizedBox(height: 12),
                _timeRow('Ends', _endDisplay),
                const SizedBox(height: 20),

                // days
                Text(
                  'Days Active',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final isActive = _days.contains(i);
                    return Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFEDB82A)
                            : const Color(0xFF252542),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFEDB82A)
                              : const Color(0xFF2A2A48),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          dayLabels[i],
                          style: GoogleFonts.poppins(
                            color: isActive
                                ? const Color(0xFF1A1208)
                                : Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const Spacer(),

          // continue — creates real schedule
          _DemoButton(
            label: 'Continue',
            onTap: () async {
              await _createSchedule(ref);
              onNext(true);
            },
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => onNext(false),
            child: Text(
              'Do this later',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _timeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: const Color(0xFFEDB82A),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Demo Screen 5 — Schedule tab mockup ──────────────

class _DemoScheduleTabScreen extends StatelessWidget {
  final VoidCallback onNext;

  const _DemoScheduleTabScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _DemoShell(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'You can edit this in\nthe schedule tab',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 32),

          // phone mockup showing schedule screen
          _PhoneMockup(
            child: _ScheduleScreenMockup(),
          ),

          const Spacer(),
          _DemoButton(label: 'Got it 👍', onTap: onNext),
        ],
      ),
    );
  }
}

// ── Demo Screen 6 — Blocking preview ─────────────────

class _DemoBlockingScreen extends StatelessWidget {
  final VoidCallback onNext;

  const _DemoBlockingScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _DemoShell(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'Your apps will be blocked\nduring your session',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 32),

          // phone mockup showing active blocking
          _PhoneMockup(
            child: _ActiveBlockingMockup(),
          ),

          const Spacer(),
          _DemoButton(label: 'Continue', onTap: onNext),
        ],
      ),
    );
  }
}

// ── Demo Screen 7 — XP intro ──────────────────────────

class _DemoXpScreen extends StatelessWidget {
  final VoidCallback onNext;

  const _DemoXpScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _DemoShell(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'Block apps to\nearn XP ⚡',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The longer you focus, the more you earn',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),

          // phone mockup showing home screen with XP
          _PhoneMockup(
            child: _HomeScreenMockup(),
          ),

          const Spacer(),
          _DemoButton(label: 'Continue', onTap: onNext),
        ],
      ),
    );
  }
}

// ── Phone mockup wrapper ──────────────────────────────

class _PhoneMockup extends StatelessWidget {
  final Widget child;

  const _PhoneMockup({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 360,
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFF3A3A5C),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: child,
        ),
      ),
    );
  }
}

// ── Schedule screen mockup ────────────────────────────

class _ScheduleScreenMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16162A),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scheduled Sessions',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDB82A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Color(0xFF1A1208), size: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // session card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDB82A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Night Mode',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '22:00 - 05:00 · Every day',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                // toggle
                Container(
                  width: 28,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDB82A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // bottom nav
          const Spacer(),
          _MockBottomNav(activeIndex: 1),
        ],
      ),
    );
  }
}

// ── Active blocking mockup ────────────────────────────

class _ActiveBlockingMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16162A),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Column(
        children: [
          // header badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white38,
                  size: 13,
                ),
              ),
              Row(
                children: [
                  _MockBadge(label: '🔥 0'),
                  const SizedBox(width: 4),
                  _MockBadge(label: '⚡ 49 XP'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // focus session card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2A48), width: 0.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3355FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF3355FF),
                    size: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Focus Session',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '00:00:57',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // progress bar
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252542),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.05,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDB82A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // buttons
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252542),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '⏸ Take A Break',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '■ Give Up',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _MockBottomNav(activeIndex: 0),
        ],
      ),
    );
  }
}

// ── Home screen mockup ────────────────────────────────

class _HomeScreenMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16162A),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Column(
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white38,
                  size: 13,
                ),
              ),
              Row(
                children: [
                  _MockBadge(label: '🔥 3'),
                  const SizedBox(width: 4),
                  _MockBadge(
                    label: '⚡ 49 XP',
                    highlighted: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // timer card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2A48), width: 0.5),
            ),
            child: Column(
              children: [
                Text(
                  'Time Blocked Today',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                // timer display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['00', '04', '00'].map((t) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252542),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (t != '00' || t == '00')
                          const Text(
                            ' : ',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    );
                  }).toList()
                    ..removeLast(),
                ),
                const SizedBox(height: 8),
                // block now button
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDB82A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '▶  Block Now',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1A1208),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // +XP floating label
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(top: 6, right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEDB82A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEDB82A).withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                '+10 XP',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1A1208),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const Spacer(),
          _MockBottomNav(activeIndex: 0),
        ],
      ),
    );
  }
}

// ── Shared mock widgets ───────────────────────────────

class _MockBadge extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _MockBadge({required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFEDB82A).withValues(alpha: 0.15)
            : const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFEDB82A).withValues(alpha: 0.4)
              : const Color(0xFF2A2A48),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: highlighted ? const Color(0xFFEDB82A) : Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MockBottomNav extends StatelessWidget {
  final int activeIndex;

  const _MockBottomNav({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home_rounded,
      Icons.calendar_today_rounded,
      Icons.bar_chart_rounded,
      Icons.settings_rounded,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A48), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (i) {
          final isActive = i == activeIndex;
          return Container(
            width: 24,
            height: 24,
            decoration: isActive
                ? const BoxDecoration(
                    color: Color(0xFFEDB82A),
                    shape: BoxShape.circle,
                  )
                : null,
            child: Icon(
              icons[i],
              color: isActive
                  ? const Color(0xFF1A1208)
                  : Colors.white.withValues(alpha: 0.3),
              size: 13,
            ),
          );
        }),
      ),
    );
  }
}

// ── Shared button widgets ─────────────────────────────

class _DemoButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const _DemoButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEDB82A),
          foregroundColor: const Color(0xFF1A1208),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
          elevation: 0,
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }
}

class _DemoSkipButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DemoSkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        'Skip for now',
        style: GoogleFonts.poppins(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Shared shell ──────────────────────────────────────

class _DemoShell extends StatelessWidget {
  final Widget child;

  const _DemoShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          // gradient bg
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
          // floating circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEDB82A).withValues(alpha: 0.04),
                border: Border.all(
                  color: const Color(0xFFEDB82A).withValues(alpha: 0.07),
                  width: 0.5,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4444AA).withValues(alpha: 0.04),
                border: Border.all(
                  color: const Color(0xFF4444AA).withValues(alpha: 0.07),
                  width: 0.5,
                ),
              ),
            ),
          ),
          // content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
