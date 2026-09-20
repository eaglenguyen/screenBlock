// lib/onboarding_new/screens/hobbies_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widget/continue_button.dart';
import '../../widget/progress_bar.dart';
import '../../widget/typewriter_title.dart';


class OnboardingHobbiesScreen extends StatefulWidget {
  final int progressStep;
  final int progressTotal;
  final VoidCallback onBack;
  final ValueChanged<List<String>> onContinue;



  const OnboardingHobbiesScreen({
    super.key,
    required this.progressStep,
    required this.progressTotal,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<OnboardingHobbiesScreen> createState() => _OnboardingHobbiesScreenState();
}

class _HobbyOption {
  const _HobbyOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _OnboardingHobbiesScreenState extends State<OnboardingHobbiesScreen> {
  final Set<String> _selected = {};
  final List<String> _customHobbies = []; // 👈 new — tracks user-added hobbies so we can render chips for them
  bool _isAddingCustom = false; // 👈 new — toggles the chip into edit mode
  final TextEditingController _customController = TextEditingController(); // 👈 new
  final FocusNode _customFocusNode = FocusNode(); // 👈 new

  @override
  void dispose() {
    _customController.dispose(); // 👈 new
    _customFocusNode.dispose(); // 👈 new
    super.dispose();
  }

  void _submitCustomHobby() { // 👈 new
    final trimmed = _customController.text.trim();
    if (trimmed.isNotEmpty && !_customHobbies.contains(trimmed)) {
      setState(() {
        _customHobbies.add(trimmed);
        _selected.add(trimmed);
        _customController.clear();
        _isAddingCustom = false;
      });
    } else {
      setState(() => _isAddingCustom = false);
    }
  }


  static const List<_HobbyOption> _options = [
    _HobbyOption('Reading', Icons.menu_book_rounded),
    _HobbyOption('Exercising', Icons.fitness_center_rounded),
    _HobbyOption('Cooking', Icons.restaurant_rounded),
    _HobbyOption('Gaming', Icons.sports_esports_rounded),
    _HobbyOption('Making Music', Icons.music_note_rounded),
    _HobbyOption('Painting', Icons.palette_rounded),
    _HobbyOption('Photography', Icons.camera_alt_rounded),
    _HobbyOption('Gardening', Icons.local_florist_rounded), // 👈 was Icons.eco_rounded — a flower reads more clearly as "gardening" than a generic leaf
    _HobbyOption('Writing', Icons.edit_note_rounded),
    _HobbyOption('Hiking', Icons.hiking_rounded),
    _HobbyOption('Yoga', Icons.self_improvement_rounded),
    _HobbyOption('Content Creation', Icons.videocam_rounded), // 👈 was Icons.cut_rounded (scissors) — didn't match at all
    _HobbyOption('Sports', Icons.sports_soccer_rounded),
    _HobbyOption('Bedrot', Icons.king_bed_rounded), // 👈 was Icons.movie_rounded — now an actual bed icon
    _HobbyOption('Traveling', Icons.flight_takeoff_rounded),
  ];

  
  IconData _iconForCustomHobby(String label) { // 👈 new
    final text = label.toLowerCase();

    const iconMap = <String, IconData>{
      // sports & fitness
      'tennis': Icons.sports_tennis_rounded,
      'basketball': Icons.sports_basketball_rounded,
      'soccer': Icons.sports_soccer_rounded,
      'football': Icons.sports_football_rounded,
      'baseball': Icons.sports_baseball_rounded,
      'golf': Icons.sports_golf_rounded,
      'volleyball': Icons.sports_volleyball_rounded,
      'swim': Icons.pool_rounded,
      'swimming': Icons.pool_rounded,
      'run': Icons.directions_run_rounded,
      'running': Icons.directions_run_rounded,
      'bike': Icons.directions_bike_rounded,
      'biking': Icons.directions_bike_rounded,
      'cycling': Icons.directions_bike_rounded,
      'boxing': Icons.sports_mma_rounded,
      'martial arts': Icons.sports_martial_arts_rounded,
      'karate': Icons.sports_martial_arts_rounded,
      'skiing': Icons.downhill_skiing_rounded,
      'snowboard': Icons.snowboarding_rounded,
      'surf': Icons.surfing_rounded,
      'surfing': Icons.surfing_rounded,
      'skate': Icons.skateboarding_rounded,
      'skating': Icons.skateboarding_rounded,
      'climb': Icons.terrain_rounded,
      'climbing': Icons.terrain_rounded,
      'rowing': Icons.rowing_rounded,
      'kayak': Icons.kayaking_rounded,
      'weightlifting': Icons.fitness_center_rounded,
      'gym': Icons.fitness_center_rounded,
      'pilates': Icons.self_improvement_rounded,

      // creative
      'draw': Icons.brush_rounded,
      'drawing': Icons.brush_rounded,
      'sketch': Icons.brush_rounded,
      'sewing': Icons.cut_rounded,
      'knitting': Icons.cut_rounded,
      'pottery': Icons.coffee_maker_rounded,
      'ceramics': Icons.coffee_maker_rounded,
      'dance': Icons.nightlife_rounded,
      'dancing': Icons.nightlife_rounded,
      'guitar': Icons.music_note_rounded,
      'piano': Icons.piano_rounded,
      'sing': Icons.mic_rounded,
      'singing': Icons.mic_rounded,
      'act': Icons.theater_comedy_rounded,
      'acting': Icons.theater_comedy_rounded,
      'theater': Icons.theater_comedy_rounded,

      // food & home
      'baking': Icons.cake_rounded,
      'bake': Icons.cake_rounded,
      'coffee': Icons.local_cafe_rounded,
      'wine': Icons.wine_bar_rounded,
      'tea': Icons.emoji_food_beverage_rounded,
      'gardening': Icons.eco_rounded,
      'plants': Icons.local_florist_rounded,

      // games & tech
      'chess': Icons.grid_view_rounded,
      'puzzle': Icons.extension_rounded,
      'puzzles': Icons.extension_rounded,
      'coding': Icons.code_rounded,
      'programming': Icons.code_rounded,
      'board games': Icons.casino_rounded,
      'cards': Icons.style_rounded,

      // outdoors
      'fishing': Icons.phishing_rounded,
      'camping': Icons.holiday_village_rounded,
      'fitness': Icons.fitness_center_rounded,
      'walking': Icons.directions_walk_rounded,
      'birdwatching': Icons.flutter_dash_rounded,

      // misc
      'pets': Icons.pets_rounded,
      'dogs': Icons.pets_rounded,
      'cats': Icons.pets_rounded,
      'astronomy': Icons.star_rounded,
      'stargazing': Icons.star_rounded,
      'meditation': Icons.self_improvement_rounded,
      'podcast': Icons.podcasts_rounded,
      'podcasts': Icons.podcasts_rounded,
    };

    // exact match first
    if (iconMap.containsKey(text)) return iconMap[text]!;

    // then substring match (so "playing tennis" or "tennis club" still matches "tennis")
    for (final entry in iconMap.entries) {
      if (text.contains(entry.key)) return entry.value;
    }

    return Icons.star_rounded; // fallback for anything unmatched
  }

  static const _pastelColors = [
    Color(0xFFEE8FA8), // pink
    Color(0xFF7FB4E8), // blue
    Color(0xFFF8D35A), // gold
    Color(0xFF7FC9BB), // teal
    Color(0xFFB398E8), // purple
    Color(0xFFEDA574), // peach
  ];

  Color _colorForIndex(int i) => _pastelColors[i % _pastelColors.length];

  void _toggle(String label) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A3728), size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: OnboardingProgressBar(step: widget.progressStep, total: widget.progressTotal)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TypewriterTitle(text: 'What are your hobbies\noutside of scrolling?', fontSize: 26),
                    const SizedBox(height: 8),
                    Text(
                      'Pick everything that sounds like you.',
                      style: GoogleFonts.poppins(color: const Color(0xFFB08A5A), fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (int i = 0; i < _options.length; i++)
                          _HobbyChip(
                            label: _options[i].label,
                            icon: _options[i].icon,
                            selected: _selected.contains(_options[i].label),
                            color: _colorForIndex(i),
                            onTap: () => _toggle(_options[i].label),
                          ),
                        for (int i = 0; i < _customHobbies.length; i++)
                          _HobbyChip(
                            label: _customHobbies[i],
                            icon: _iconForCustomHobby(_customHobbies[i]), // 👈 was: Icons.star_rounded
                            selected: _selected.contains(_customHobbies[i]),
                            color: _colorForIndex(_options.length + i),
                            onTap: () => _toggle(_customHobbies[i]),
                            onDelete: () {
                              final label = _customHobbies[i];
                              setState(() {
                                _customHobbies.removeAt(i);
                                _selected.remove(label);
                              });
                            },
                          ),
                        _isAddingCustom // 👈 new — swaps between the "Add your own" chip and the inline text field chip
                            ? _InlineAddChip(
                          controller: _customController,
                          focusNode: _customFocusNode,
                          onSubmit: _submitCustomHobby,
                          onCancel: () => setState(() {
                            _customController.clear();
                            _isAddingCustom = false;
                          }),
                        )
                            : _AddYourOwnChip(
                          onTap: () {
                            setState(() => _isAddingCustom = true);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _customFocusNode.requestFocus();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: OnboardingContinueButton(
                label: 'Continue',
                enabled: _selected.isNotEmpty,
                onTap: () => widget.onContinue(_selected.toList()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptCustomHobby(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add your own',
                style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF0E6D8), width: 1),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'e.g. Chess',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFFB08A5A)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: const Color(0xFFB08A5A),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7DD3B0),
                        foregroundColor: const Color(0xFF0F4A32),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HobbyChip extends StatelessWidget {
  const _HobbyChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
    this.onDelete, // 👈 new — optional, only custom chips pass this

  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onDelete; // 👈 new


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          left: 14,
          right: onDelete != null ? 8 : 14, // 👈 new — tighter right padding when the x icon is present
          top: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? color : const Color(0xFFF0E6D8),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? color : const Color(0xFF4A3728)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4A3728),
              ),
            ),
            if (onDelete != null) ...[ // 👈 new — the delete x, only for custom chips
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A3728).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF4A3728)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _AddYourOwnChip extends StatelessWidget {
  const _AddYourOwnChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFFF0E6D8), width: 1, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: Color(0xFF4A3728)),
            const SizedBox(width: 8),
            Text(
              'Add your own',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF4A3728)),
            ),
          ],
        ),
      ),
    );
  }
}



class _InlineAddChip extends StatelessWidget { // 👈 new
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _InlineAddChip({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 14, top: 6, bottom: 6), // 👈 flipped — was left: 14, right: 6
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFF7DD3B0), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector( // 👈 moved to the front
            onTap: onSubmit,
            child: const SizedBox(
              width: 30,
              height: 30,
              child: Icon(Icons.add_rounded, size: 18, color: Color(0xFF4A3728)),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onSubmitted: (_) => onSubmit(),
              style: GoogleFonts.poppins(color: const Color(0xFF4A3728), fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Add your own',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFFB08A5A)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFB08A5A)),
            ),
          ),
        ],
      ),
    );
  }
}