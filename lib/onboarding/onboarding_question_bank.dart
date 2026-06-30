import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausenow/onboarding/widgets/mascot_character.dart';

// ── Shared shell ──────────────────────────────────────

class _QBShell extends StatelessWidget {
  final Widget child;
  final double? progress; // 👈 0.0 to 1.0
  final VoidCallback? onBack; // 👈 optional back handler

  const _QBShell({
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

class _ContinueButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  const _ContinueButton({this.onTap, this.label = 'Continue →'});

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
            textStyle: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ── Shared choice card (matches QBGoalsScreen style) ──

class _QBChoiceCard extends StatelessWidget {
  final String? emoji;
  final String title;
  final String? sub;
  final bool isSelected;
  final VoidCallback onTap;

  const _QBChoiceCard({
    this.emoji,
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
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                        color: isSelected ? const Color(0xFFEDB82A) : Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w700,
                      )),
                  if (sub != null)
                    Text(sub!,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12, height: 1.4,
                      )),
                ],
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
    {'emoji': '🧘', 'title': 'Less anxiety', 'sub': 'Be more present in the moment'},
    {'emoji': '📵', 'title': 'More time offline', 'sub': 'Disconnect and live more intentionally'},
    {'emoji': '⚡', 'title': 'Be more productive', 'sub': 'Focus deeper and get more done'},
    {'emoji': '📱', 'title': 'Reduce social media', 'sub': 'Break the scroll and reclaim your time'},
    {'emoji': '🔄', 'title': 'Build better habits', 'sub': 'Unlearn old patterns, create new ones'},
  ];

  @override
  Widget build(BuildContext context) {
    return _QBShell(
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
                const TextSpan(text: 'let\'s start with your '),
                TextSpan(
                  text: 'goals',
                  style: const TextStyle(color: Color(0xFFEDB82A)),
                ),
                const TextSpan(text: ' for pause now'),
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
                return _QBChoiceCard(
                  emoji: goal['emoji']!,
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
          _ContinueButton(
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
    return _QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Looking into the future...',
              style: GoogleFonts.poppins(
                color: const Color(0xFFEDB82A), fontSize: 14, fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text('What does your life\nlook like with less\nphone time?',
              style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 30,
                fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.2,
              )),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = _options[i];
                return _QBChoiceCard(
                  emoji: opt['emoji']!,
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
  final VoidCallback? onBack;   // 👈 add
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
    if (m == 0) return '${h}h';
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
    return _QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('How much time do\nyou spend on your\nphone daily?',
              style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 30,
                fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.2,
              )),
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
                Text('8h', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
              ],
            ),
          ),
          const Spacer(flex: 3),
          _ContinueButton(onTap: () => widget.onNext(_hours)),
        ],
      ),
    );
  }
}

// ── QB4 — Social Media Relationship (single choice) ──

class QBSocialMediaRelationshipScreen extends StatefulWidget {
  final Function(String answer) onNext;
  final VoidCallback? onBack;   // 👈 add
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
    {'emoji': '🤖', 'title': 'It controls me more than I control it', 'sub': 'Hard to put it down once I start'},
    {'emoji': '🤷', 'title': 'I use it a lot but I can stop when I want', 'sub': 'Not addicted, just... a lot'},
    {'emoji': '💔', 'title': 'It\'s a love/hate thing', 'sub': 'Enjoy it in the moment, regret it after'},
    {'emoji': '✅', 'title': 'I\'m pretty healthy about it', 'sub': 'Just looking to fine-tune my habits'},
  ];

  @override
  Widget build(BuildContext context) {
    return _QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('What\'s your relationship\nwith your phone and\nsocial media?',
              style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 30,
                fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.2,
              )),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = _options[i];
                return _QBChoiceCard(
                  emoji: opt['emoji']!,
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

// ── QB5 — Blockers (multi-select) ────────────────────

class QBBlockersScreen extends StatefulWidget {
  final Function(List<String> answers) onNext;
  final VoidCallback? onBack;   // 👈 add
  final double progress;


  const QBBlockersScreen({super.key, required this.onNext, this.onBack, required this.progress});

  @override
  State<QBBlockersScreen> createState() => _QBBlockersScreenState();
}

class _QBBlockersScreenState extends State<QBBlockersScreen> {
  final Set<int> _selected = {};

  final List<Map<String, String>> _options = [
    {'emoji': '😴', 'title': 'Boredom', 'sub': 'I just pick it up without thinking'},
    {'emoji': '😰', 'title': 'Stress', 'sub': 'Scrolling helps me decompress'},
    {'emoji': '👀', 'title': 'FOMO', 'sub': 'I don\'t want to miss anything'},
    {'emoji': '🔁', 'title': 'Habit', 'sub': 'It\'s just automatic at this point'},
    {'emoji': '😞', 'title': 'Loneliness', 'sub': 'It fills the silence'},
  ];

  @override
  Widget build(BuildContext context) {
    return _QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Let\'s get to the root',
              style: GoogleFonts.poppins(
                color: const Color(0xFFEDB82A), fontSize: 14, fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text('What\'s the main thing\ngetting in the way\nof a better habit?',
              style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 30,
                fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.2,
              )),
          const SizedBox(height: 8),
          Text('Pick all that apply',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 14,
              )),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = _options[i];
                return _QBChoiceCard(
                  emoji: opt['emoji']!,
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
          _ContinueButton(
            onTap: _selected.isNotEmpty
                ? () => widget.onNext(_selected.map((i) => _options[i]['title']!).toList())
                : null,
          ),
        ],
      ),
    );
  }
}

// ── QB6 — Deep Struggles (multi-select) ───────────────

class QBStrugglesScreen extends StatefulWidget {
  final Function(List<String> answers) onNext;
  final VoidCallback? onBack;   // 👈 add
  final double progress;

  const QBStrugglesScreen({super.key, required this.onNext, this.onBack, required this.progress});

  @override
  State<QBStrugglesScreen> createState() => _QBStrugglesScreenState();
}

class _QBStrugglesScreenState extends State<QBStrugglesScreen> {
  final Set<int> _selected = {};

  final List<Map<String, String>> _options = [
    {'emoji': '🌀', 'title': 'Anxiety or overthinking', 'sub': 'Mind won\'t stop racing'},
    {'emoji': '🔋', 'title': 'Low motivation', 'sub': 'Feeling stuck and stagnant'},
    {'emoji': '🫪', 'title': 'Easily Distracted', 'sub': 'Hard time focusing on one thing'},
    {'emoji': '⏳', 'title': 'Procrastination', 'sub': 'Always putting things off'},
    {'emoji': '🙅', 'title': 'None of these really apply', 'sub': 'I\'m doing okay here'},
  ];

  @override
  Widget build(BuildContext context) {
    return _QBShell(
      progress: widget.progress,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.2,
              ),
              children: [
                const TextSpan(
                  text: 'deep ',
                ),
                TextSpan(
                  text: 'rooted issues',
                  style: const TextStyle(color: Color(0xFFEDB82A)),
                ),
                const TextSpan(
                  text: ' can\nget in the way, does any\nof this apply to you?',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final opt = _options[i];
                return _QBChoiceCard(
                  emoji: opt['emoji']!,
                  title: opt['title']!,
                  sub: opt['sub']!,
                  isSelected: _selected.contains(i),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (i == 4) {
                        _selected.clear();
                        _selected.add(4);
                      } else {
                        _selected.remove(4);
                        _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _ContinueButton(
            onTap: _selected.isNotEmpty
                ? () => widget.onNext(_selected.map((i) => _options[i]['title']!).toList())
                : null,
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
    return _QBShell(
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
                return _QBChoiceCard(
                  emoji: level['emoji'] as String,
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
    return _QBShell(
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
          _ContinueButton(onTap: onNext, label: 'Let\'s build your plan →'),
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
    return _QBShell(
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
          _ContinueButton(onTap: onNext, label: 'I\'ll give it a shot →'),
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
    return _QBShell(
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
            'You\'re not alone ❤️ — now you\'ve got\nus working in your corner.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 15,
              height: 1.55,
            ),
          ),

          const Spacer(flex: 3),

          _ContinueButton(
            onTap: onNext,
            label: 'Show me how this works ',
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