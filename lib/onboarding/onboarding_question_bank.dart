import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausenow/onboarding/widgets/mascot_character.dart';

import 'onboarding_animations.dart';

// ── Shared shell ──────────────────────────────────────

class QBShell extends StatelessWidget {
  final Widget child;
  final double? progress; // 👈 0.0 to 1.0
  final VoidCallback? onBack; // 👈 optional back handler

  const QBShell({super.key,
    required this.child,
    this.progress,
    this.onBack
  });

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
                colors: [Color(0xFF1a0a3d), Color(0xFF16162a), Color(0xFF0a1a2a)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEDB82A).withValues(alpha: 0.04),
                border: Border.all(color: const Color(0xFFEDB82A).withValues(alpha: 0.07), width: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: 100, left: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4444AA).withValues(alpha: 0.04),
                border: Border.all(color: const Color(0xFF4444AA).withValues(alpha: 0.07), width: 0.5),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 👇 top bar with back button and progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      // back button
                      if (onBack != null)
                        GestureDetector(
                          onTap: onBack,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 36),

                      const SizedBox(width: 12),

                      // progress bar
                      if (progress != null)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFEDB82A),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),

                      const SizedBox(width: 48), // balance the back button
                    ],
                  ),
                ),

                // content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ── Shared continue button ────────────────────────────

class ContinueButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  const ContinueButton({super.key, this.onTap, this.label = 'Continue'});

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

// ── Shared choice card (matches QBGoalsScreen style) ──
class QBChoiceCard extends StatelessWidget {
  final int? index; // 👈 new — replaces emoji as the leading visual
  final String title;
  final String? sub;
  final bool isSelected;
  final VoidCallback onTap;

  const QBChoiceCard({
    this.index, // 👈 new
    required this.title,
    this.sub,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            if (index != null) ...[ // 👈 was `if (emoji != null)`
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFFEDB82A)
                      : Colors.white.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: GoogleFonts.poppins(
                      color: isSelected
                          ? const Color(0xFF1A1208)
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                        color: isSelected ? const Color(0xFFEDB82A) : Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w700,
                      )),
                  if (sub != null && sub!.isNotEmpty) ... [
                    const SizedBox(height: 4,),
                    Text(sub!,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12, height: 1.4,
                        )),
                  ],],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFEDB82A) : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFEDB82A)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Color(0xFF1A1208), size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}


// ── QB1 — Goals Picker ────────────────────────────────

class QBGoalsScreen extends StatefulWidget {
  final Function(List<String> goals) onNext;
  final VoidCallback? onBack;   // 👈 add
  final double progress;



  const QBGoalsScreen({
    super.key,
    required this.onNext,
    this.onBack,
    required this.progress
  });

  @override
  State<QBGoalsScreen> createState() => _QBGoalsScreenState();
}

class _QBGoalsScreenState extends State<QBGoalsScreen> {
  final Set<int> _selected = {};

  final List<Map<String, String>> _goals = [
    {'emoji': '🧘', 'title': 'More Mindful', 'sub': 'Make better decisions'},
    {'emoji': '📵', 'title': 'More time offline', 'sub': 'Disconnect and live more intentionally'},
    {'emoji': '⚡', 'title': 'Be more productive', 'sub': 'Focus deeper and get more done'},
    {'emoji': '📱', 'title': 'Reduce social media', 'sub': 'Break the scroll and reclaim your time'},
    {'emoji': '🔄', 'title': 'Build better habits', 'sub': 'Unlearn old patterns, create new ones'},
  ];

  @override
  Widget build(BuildContext context) {
    return QBShell(
      progress: widget.progress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.2,
              ),
              children: [
                const TextSpan(text: 'What are your '),
                TextSpan(
                  text: 'goals',
                  style: const TextStyle(color: Color(0xFFEDB82A)),
                ),
                const TextSpan(text: ' using pause now'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Pick 1 to 3 that apply',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 15,
              )),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final goal = _goals[i];
                return QBChoiceCard(
                  index: i + 1, // 👈 was emoji: opt['emoji']!
                  title: goal['title']!,
                  sub: goal['sub']!,
                  isSelected: _selected.contains(i),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (_selected.contains(i)) {
                        _selected.remove(i);
                      } else {
                        if (_selected.length < 3) _selected.add(i);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ContinueButton(
            onTap: _selected.isNotEmpty
                ? () => widget.onNext(_selected.map((i) => _goals[i]['title']!).toList())
                : null,
          ),
        ],
      ),
    );
  }
}

// ── QB2 — Future Vision (single choice) ───────────────

class QBFutureVisionScreen extends StatefulWidget {
  final Function(String answer) onNext;
  final VoidCallback? onBack;   // 👈 add
  final double progress;


  const QBFutureVisionScreen({super.key,
    required this.onNext,
    this.onBack,
    required this.progress
  });

  @override
  State<QBFutureVisionScreen> createState() => _QBFutureVisionScreenState();
}

class _QBFutureVisionScreenState extends State<QBFutureVisionScreen> {
  int? _selected;

  final List<Map<String, String>> _options = [
    {'emoji': '❤️', 'title': 'More time for the people I love', 'sub': 'Deeper connections, more presence'},
    {'emoji': '🎯', 'title': 'Sharper focus and better work', 'sub': 'Less distraction, more flow state'},
    {'emoji': '🧘', 'title': 'A calmer, less anxious mind', 'sub': 'Peace over constant stimulation'},
    {'emoji': '🌅', 'title': 'More present in everyday moments', 'sub': 'Actually living, not just scrolling'},
    {'emoji': '🔥', 'title': 'Doing more of what actually matters', 'sub': 'Priorities over distractions'},
  ];

  @override
  Widget build(BuildContext context) {
    return QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.2,
              ),
              children: [
                const TextSpan(text: 'What does your '),
                TextSpan(
                  text: 'future',
                  style: TextStyle(color: Color(0xFFEDB82A)),
                ),
                const TextSpan(text: '\nlook like with less\nphone time?'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = _options[i];
                return QBChoiceCard(
                  index: i + 1, // 👈 was emoji: opt['emoji']!
                  title: opt['title']!,
                  sub: opt['sub']!,
                  isSelected: _selected == i,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selected = i);
                    Future.delayed(const Duration(milliseconds: 300),
                            () => widget.onNext(opt['title']!));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── QB3 — Phone Usage Slider ──────────────────────────

class QBPhoneUsageScreen extends StatefulWidget {
  final Function(double hours) onNext;
  final VoidCallback? onBack;
  final double progress;

  const QBPhoneUsageScreen({
    super.key,
    required this.onNext,
    this.onBack,
    required this.progress
  });

  @override
  State<QBPhoneUsageScreen> createState() => _QBPhoneUsageScreenState();
}

class _QBPhoneUsageScreenState extends State<QBPhoneUsageScreen> {
  double _hours = 4.0;

  String get _label {
    final h = _hours.floor();
    final m = ((_hours - h) * 60).round();
    if (m == 0) return '${h}h+';
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String get _description {
    if (_hours <= 1) return 'Very mindful 🌱';
    if (_hours <= 2) return 'Pretty good 👍';
    if (_hours <= 4) return 'Room to improve ⚡';
    if (_hours <= 6) return 'That\'s a lot 😬';
    return 'Let\'s change that 🔥';
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

          // 👇 mascot + speech bubble, replacing the plain headline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                  child: Transform.scale(
                    scale: 1.4, // 👈 new — zooms the image in beyond the circle's edge, cropped by clipBehavior
                    child: Image.asset(
                      'assets/icons/square_notes_cutout.png',
                      fit: BoxFit.cover,
                    ),
                  ),
              ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252542),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'How much time do you\nspend on your phone daily?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),


            ],
          ),

          const Spacer(flex: 2),
          Center(
            child: Text(_label,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFEDB82A), fontSize: 64,
                  fontWeight: FontWeight.w800, letterSpacing: -2,
                )),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(_description,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 15,
                )),
          ),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFEDB82A),
              inactiveTrackColor: const Color(0xFFEDB82A).withValues(alpha: 0.15),
              thumbColor: const Color(0xFFEDB82A),
              overlayColor: const Color(0xFFEDB82A).withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 5,
            ),
            child: Slider(
              value: _hours, min: 0, max: 8, divisions: 16,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _hours = val);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0h', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                Text('8h+', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
              ],
            ),
          ),
          const Spacer(flex: 3),
          ContinueButton(onTap: () => widget.onNext(_hours)),
        ],
      ),
    );
  }
}

// ── QB4 — Social Media Relationship (single choice) ──
class QBSocialMediaRelationshipScreen extends StatefulWidget {
  final Function(String answer) onNext;
  final VoidCallback? onBack;
  final double progress;
  const QBSocialMediaRelationshipScreen({
    super.key,
    required this.onNext,
    this.onBack,
    required this.progress
  });
  @override
  State<QBSocialMediaRelationshipScreen> createState() => _QBSocialMediaRelationshipScreenState();
}
class _QBSocialMediaRelationshipScreenState extends State<QBSocialMediaRelationshipScreen> {
  int? _selected;
  final List<Map<String, String>> _options = [
    {'emoji': '🤖', 'title': 'It controls me more than I control it'},
    {'emoji': '🤷', 'title': 'I use it a lot but I can stop when I want'},
    {'emoji': '💔', 'title': 'It\'s a love/hate thing'},
    {'emoji': '✅', 'title': 'I\'m pretty healthy about it'},
  ];
  @override
  Widget build(BuildContext context) {
    return QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Transform.scale(
                    scale: 1.4,
                    child: Image.asset(
                      'assets/icons/square_notes_cutout.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252542),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'What\'s your relationship with your phone and social media?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = _options[i];
                return QBChoiceCard(
                  index: i + 1, // 👈 was emoji: opt['emoji']!
                  title: opt['title']!,
                  sub: opt['sub'], // 👈 no fallback, no `!` — just pass through as nullable
                  isSelected: _selected == i,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selected = i);
                    Future.delayed(const Duration(milliseconds: 300),
                            () => widget.onNext(opt['title']!));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── QB5 — Blockers (multi-select) ────────────────────
class QBBlockersScreen extends StatefulWidget {
  final Function(List<String> answers) onNext;
  final VoidCallback? onBack;
  final double progress;
  const QBBlockersScreen({super.key, required this.onNext, this.onBack, required this.progress});
  @override
  State<QBBlockersScreen> createState() => _QBBlockersScreenState();
}
class _QBBlockersScreenState extends State<QBBlockersScreen> {
  final Set<int> _selected = {};
  final List<Map<String, String>> _options = [
    {'title': 'Addicted', 'sub': 'I love scrolling too much'},
    {'title': 'Stress', 'sub': 'Scrolling helps me decompress'},
    {'title': 'FOMO', 'sub': 'I don\'t want to miss anything'},
    {'title': 'Job', 'sub': 'My job requires me to scroll'},
    {'title': 'Bad Habit', 'sub': 'I just scroll without thinking'},
  ];
  @override
  Widget build(BuildContext context) {
    return QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Transform.scale(
                    scale: 1.4,
                    child: Image.asset(
                      'assets/icons/square_notes_cutout.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252542),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Why can you not stop scrolling?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = _options[i];
                return QBChoiceCard(
                  index: i + 1, // 👈 was emoji: opt['emoji']!
                  title: opt['title']!,
                  sub: opt['sub']!,
                  isSelected: _selected.contains(i),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selected.contains(i)
                        ? _selected.remove(i)
                        : _selected.add(i));
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ContinueButton(
            onTap: _selected.isNotEmpty
                ? () => widget.onNext(_selected.map((i) => _options[i]['title']!).toList())
                : null,
          ),
        ],
      ),
    );
  }
}

// ── QB6 — What You'd Rather Be Doing (multi-select) ───────────────
class QBStrugglesScreen extends StatefulWidget {
  final Function(List<String> answers) onNext;
  final VoidCallback? onBack;
  final double progress;
  const QBStrugglesScreen({super.key, required this.onNext, this.onBack, required this.progress});
  @override
  State<QBStrugglesScreen> createState() => _QBStrugglesScreenState();
}
class _QBStrugglesScreenState extends State<QBStrugglesScreen> {
  final Set<int> _selected = {};
  final List<Map<String, String>> _options = [
    {'emoji': '📚', 'title': 'Reading or learning', 'sub': 'Books, courses, new skills'},
    {'emoji': '💪', 'title': 'Exercise or movement', 'sub': 'Getting active, feeling better'},
    {'emoji': '👥', 'title': 'Time with people', 'sub': 'Friends, family, real conversations'},
    {'emoji': '🎯', 'title': 'Working on my goals', 'sub': 'Projects that actually matter to me'},
    {'emoji': '😴', 'title': 'Just resting', 'sub': 'Sleeping more, actually relaxing'},
  ];
  @override
  Widget build(BuildContext context) {
    return QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Transform.scale(
                    scale: 1.4,
                    child: Image.asset(
                      'assets/icons/square_notes_cutout.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252542),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                      children: [
                        const TextSpan(text: 'if you stopped '),
                        TextSpan(
                          text: 'doom scrolling',
                          style: const TextStyle(color: Color(0xFFEDB82A)),
                        ),
                        const TextSpan(text: ', what would you spend more time doing?'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = _options[i];
                return QBChoiceCard(
                  index: i + 1, // 👈 was emoji: opt['emoji']!
                  title: opt['title']!,
                  sub: opt['sub']!,
                  isSelected: _selected.contains(i),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ContinueButton(
            onTap: _selected.isNotEmpty
                ? () => widget.onNext(_selected.map((i) => _options[i]['title']!).toList())
                : null,
          ),
        ],
      ),
    );
  }
}


class QBSingleChoiceScreen extends StatefulWidget {
  final String question;
  final List<String> options;
  final Function(String answer) onSelected;
  final VoidCallback? onBack;
  final double progress;

  const QBSingleChoiceScreen({
    super.key,
    required this.question,
    required this.options,
    required this.onSelected,
    this.onBack,
    required this.progress,
  });

  @override
  State<QBSingleChoiceScreen> createState() => _QBSingleChoiceScreenState();
}

class _QBSingleChoiceScreenState extends State<QBSingleChoiceScreen> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    return QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Transform.scale(
                    scale: 1.4,
                    child: Image.asset(
                      'assets/icons/square_notes_cutout.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252542),
                    borderRadius: BorderRadius.circular(18),

                  ),
                  child: Text(
                    widget.question,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          ...List.generate(widget.options.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QBChoiceCard(
                index: i + 1,
                title: widget.options[i],
                isSelected: _selected == i,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selected = i);
                  Future.delayed(const Duration(milliseconds: 300),
                          () => widget.onSelected(widget.options[i]));
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class QBInfoScreen extends StatefulWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const QBInfoScreen({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.onNext,
    this.onBack,
  });

  @override
  State<QBInfoScreen> createState() => _QBInfoScreenState();
}

class _QBInfoScreenState extends State<QBInfoScreen>
    with SingleTickerProviderStateMixin, OnboardingEntranceMixin {
  @override
  void initState() {
    super.initState();
    initEntrance(elementCount: 4, speedMultiplier: 5); // 👈 doubles the duration — 720ms → 1440ms
  }

  @override
  void dispose() {
    disposeEntrance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16162A),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // 0 — image
                  staggered(
                    0,
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        widget.imageAsset,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 1 — title
                  staggered(
                    1,
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2 — subtitle
                  staggered(
                    2,
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // 3 — button
                  staggered(
                    3,
                    ContinueButton(onTap: widget.onNext),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Commitment Screen ─────────────────────────────────

class QBCommitmentScreen extends StatefulWidget {
  final Function(String level, bool isHighCommitment) onNext;
  const QBCommitmentScreen({super.key, required this.onNext});

  @override
  State<QBCommitmentScreen> createState() => _QBCommitmentScreenState();
}

class _QBCommitmentScreenState extends State<QBCommitmentScreen> {
  int? _selected;

  final List<Map<String, dynamic>> _levels = [
    {'emoji': '🔥', 'title': 'Super committed', 'sub': 'I\'m all in — ready to do whatever it takes', 'high': true},
    {'emoji': '💪', 'title': 'Committed', 'sub': 'I\'m serious about this and ready to start', 'high': true},
    {'emoji': '🙂', 'title': 'Somewhat committed', 'sub': 'I want to try but life gets in the way', 'high': false},
    {'emoji': '😐', 'title': 'A little committed', 'sub': 'I\'m curious but not sure I\'m ready', 'high': false},
    {'emoji': '🤔', 'title': 'Not sure yet', 'sub': 'Still figuring out if this is for me', 'high': false},
  ];

  @override
  Widget build(BuildContext context) {
    return QBShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const SizedBox(height: 8),
          Text('How committed are\nyou to making\na change?',
              style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 30,
                fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.2,
              )),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: _levels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final level = _levels[i];
                return QBChoiceCard(
                  index: i + 1, // 👈 was emoji: opt['emoji']!
                  title: level['title'] as String,
                  sub: level['sub'] as String,
                  isSelected: _selected == i,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selected = i);
                    Future.delayed(const Duration(milliseconds: 300),
                            () => widget.onNext(level['title'] as String, level['high'] as bool));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Commitment Branch A — High ────────────────────────

class QBCommitmentHighScreen extends StatelessWidget {
  final String level;
  final VoidCallback onNext;
  const QBCommitmentHighScreen({super.key, required this.level, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return QBShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          const Center(child: Text('🔥', style: TextStyle(fontSize: 72))),
          const SizedBox(height: 28),
          Text('That\'s the energy\nwe love to see.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 32,
                fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.2,
              )),
          const SizedBox(height: 16),
          Text('People who commit at your level see results\nwithin the first week. You\'re already ahead.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 15, height: 1.5,
              )),
          const Spacer(flex: 3),
          ContinueButton(onTap: onNext, label: 'Finish Up'),
        ],
      ),
    );
  }
}

// ── Commitment Branch B — Low ─────────────────────────

class QBCommitmentLowScreen extends StatelessWidget {
  final String level;
  final VoidCallback onNext;
  const QBCommitmentLowScreen({super.key, required this.level, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return QBShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          const Center(child: Text('💙', style: TextStyle(fontSize: 72))),
          const SizedBox(height: 28),
          Text('That\'s okay.\nHonesty is the\nfirst step.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 32,
                fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.2,
              )),
          const SizedBox(height: 16),
          Text('You don\'t need to be ready —\n you just need to start.\npause now is designed to make change\nfeel easy, not overwhelming.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 15, height: 1.5,
              )),
          const Spacer(flex: 3),
          ContinueButton(onTap: onNext, label: 'I\'ll give it a shot'),
        ],
      ),
    );
  }
}


// timepicker screens

class QBTimePickerScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final TimeOfDay initialTime;
  final Function(TimeOfDay time) onContinue;
  final VoidCallback? onBack;
  final double progress; // 👈 new

  const QBTimePickerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.initialTime,
    required this.onContinue,
    this.onBack,
    required this.progress, // 👈 new
  });

  @override
  State<QBTimePickerScreen> createState() => _QBTimePickerScreenState();
}

class _QBTimePickerScreenState extends State<QBTimePickerScreen> {
  late DateTime _picked;

  @override
  void initState() {
    super.initState();
    _picked = DateTime(2024, 1, 1, widget.initialTime.hour, widget.initialTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return QBShell( // 👈 was Scaffold(...Stack(...))
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Container(
            height: 216,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _picked,
                use24hFormat: false,
                onDateTimeChanged: (dt) => _picked = dt,
              ),
            ),
          ),
          const Spacer(),
          ContinueButton(
            onTap: () => widget.onContinue(
              TimeOfDay(hour: _picked.hour, minute: _picked.minute),
            ),
          ),
        ],
      ),
    );
  }
}


class QBRealisticTargetScreen extends StatelessWidget {
  final TimeOfDay blockTime;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final double progress; // 👈 new

  const QBRealisticTargetScreen({
    super.key,
    required this.blockTime,
    required this.onNext,
    this.onBack,
    required this.progress, // 👈 new
  });

  String get _formattedTime {
    final hour = blockTime.hourOfPeriod == 0 ? 12 : blockTime.hourOfPeriod;
    final minute = blockTime.minute.toString().padLeft(2, '0');
    final period = blockTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return QBShell( // 👈 was Scaffold(...Stack(...))
      progress: progress,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Spacer(flex: 2),
          Text.rich(
            TextSpan(
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.3,
              ),
              children: [
                const TextSpan(text: 'Blocking your apps at '),
                TextSpan(
                  text: _formattedTime,
                  style: const TextStyle(color: Color(0xFFEDB82A)),
                ),
                const TextSpan(text: ' is a realistic target. It\'s not hard at all!'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '90% of users say that they scroll much less after using pause now.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const Spacer(flex: 3),
          ContinueButton(onTap: onNext),
        ],
      ),
    );
  }
}

// Sympathy Screen

class QBSympathyScreen extends StatelessWidget {
  final String userName;
  final VoidCallback onNext;

  const QBSympathyScreen({
    super.key,
    required this.userName,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return QBShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),

          // mascot
          const Center(child: MascotCharacter(size: 160, rivFile: 'assets/rive/mr_square_plan.riv',)),
          const SizedBox(height: 32),

          // headline
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.3,
              ),
              children: [
                const TextSpan(text: 'No worries'),
                if (userName.isNotEmpty) ...[
                  const TextSpan(text: ', '),
                  TextSpan(
                    text: userName,
                    style: const TextStyle(color: Color(0xFFEDB82A)),
                  ),
                ],
                const TextSpan(
                  text: '.\nWe\'ll work on a plan \njust for you.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re not alone ❤️ — you\'re one of\nmillions trying to better their life too.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 15,
              height: 1.55,
            ),
          ),

          const Spacer(flex: 3),

          ContinueButton(
            onTap: onNext,
            label: 'Start my transformation',
          ),
        ],
      ),
    );
  }
}


// Fake Loading
class OnboardingLoadingPlanScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingLoadingPlanScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingLoadingPlanScreen> createState() =>
      _OnboardingLoadingPlanScreenState();
}

class _OnboardingLoadingPlanScreenState
    extends State<OnboardingLoadingPlanScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _progressCtrl;
  Timer? _intervalTimer;
  int _checkedDots = 0;
  int _textIndex = 0;

  final List<String> _dots = [
    'Analyzing your habits...',
    'Calculating screen time impact...',
    'Building your goal roadmap...',
    'Personalizing your app...',
    'Optimizing your schedule...',
    'Finalizing recommendations...',
  ];

  final List<String> _calculations = [
    'Processing your data...',
    'Matching with 1,000+ users like you...',
    'Identifying your peak focus windows...',
    'Calculating your 30-day projection...',
    'Making sure this is tailored for you...',
    'Your app is almost ready...',
  ];

  @override
  void initState() {
    super.initState();

    // progress circle animates over 10 seconds
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _progressCtrl.forward();

    // check off a dot every ~1.6 seconds (6 dots over 10 seconds)
    _intervalTimer = Timer.periodic(
      const Duration(milliseconds: 1600),
          (timer) {
        if (!mounted) return;
        setState(() {
          if (_checkedDots < _dots.length) {
            _checkedDots++;
            _textIndex = (_checkedDots).clamp(0, _calculations.length - 1);
            HapticFeedback.mediumImpact(); // 👈 add this

          }
        });

        if (_checkedDots >= _dots.length) {
          timer.cancel();
          // small delay then advance
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) widget.onComplete();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _intervalTimer?.cancel();
    super.dispose();
  }

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
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // headline
                  Text(
                    'Building your\npersonalized plan',
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
                    'This only takes a moment',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 👇 big progress circle — center of attention
                  Center(
                    child: AnimatedBuilder(
                      animation: _progressCtrl,
                      builder: (_, __) => SizedBox(
                        width: 180, // 👈 was 100
                        height: 180, // 👈 was 100
                        child: CustomPaint(
                          painter: _ProgressRingPainter(
                            progress: _progressCtrl.value,
                          ),
                          child: Center(
                            child: Text(
                              '${(_progressCtrl.value * 100).round()}%',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFEDB82A),
                                fontSize: 40, // 👈 was 22
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // cycling calculation text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _calculations[_textIndex],
                      key: ValueKey(_textIndex),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 👇 dots list below circle
                  ...List.generate(_dots.length, (i) {
                    final isChecked = i < _checkedDots;
                    final isActive = i == _checkedDots;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AnimatedOpacity(
                        opacity: isChecked || isActive ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 400),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isChecked
                                    ? const Color(0xFFEDB82A)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isChecked
                                      ? const Color(0xFFEDB82A)
                                      : isActive
                                      ? const Color(0xFFEDB82A)
                                      .withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(Icons.check_rounded,
                                  color: Color(0xFF1A1208), size: 14)
                                  : isActive
                                  ? Center(child: _PulsingDot())
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              _dots[i],
                              style: GoogleFonts.poppins(
                                color: isChecked
                                    ? Colors.white
                                    : isActive
                                    ? const Color(0xFFEDB82A)
                                    : Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ── Pulsing dot for active step ───────────────────────

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFFEDB82A).withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Progress ring painter ─────────────────────────────

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  const _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );

    // progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = const Color(0xFFEDB82A)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress;
}