import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:flutter_svg/svg.dart';

/// A looping, animated mockup of the iOS FamilyActivityPicker flow:
/// sheet opens -> tap a category to expand it -> tap the target app -> checkmark -> Choose tapped.
/// Not real footage of the system picker (can't be captured) — an illustrative walkthrough
/// so first-time users understand what they'll see and what to do.



class QuickBlockPickerTutorialOverlay extends StatelessWidget {
  final String appName;
  final VoidCallback onDismiss;

  const QuickBlockPickerTutorialOverlay({
    super.key,
    required this.appName,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, {required String appName}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => QuickBlockPickerTutorialOverlay(
        appName: appName,
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Block $appName',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reset in settings if you made a mistake',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _PickerAnimation(appName: appName),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onDismiss();
            },
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                  ),
                  child: const Center(
                    child: Text('☝', style: TextStyle(fontSize: 30)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIconSpec {
  final String asset;
  final Color color;
  final Color? bg; // 👈 null = transparent, only set for icons that need contrast
  const _AppIconSpec(this.asset, this.color, {this.bg});
}

const Map<String, _AppIconSpec> _appIcons = {
  'TikTok': _AppIconSpec('assets/icons/tiktok.svg', Colors.white, bg: Colors.black),
  'Instagram': _AppIconSpec('assets/icons/instagram.svg', Color(0xFFE1306C)),
  'YouTube': _AppIconSpec('assets/icons/youtube.svg', Color(0xFFFF0000)),
  'Facebook': _AppIconSpec('assets/icons/facebook.svg', Color(0xFF1877F2)),
  'Twitter': _AppIconSpec('assets/icons/twitter-x.svg', Colors.black, bg: Colors.white),
  'Snapchat': _AppIconSpec('assets/icons/snapchat.svg', Color(0xFFB89400)),
};

class _PickerAnimation extends StatefulWidget {
  final String appName;
  const _PickerAnimation({required this.appName});

  @override
  State<_PickerAnimation> createState() => _PickerAnimationState();
}

enum _Step { sheetIn, categoryTap, categoryOpen, appTap, checked, saveTap, reset }

class _PickerAnimationState extends State<_PickerAnimation> {
  _Step _step = _Step.sheetIn;

  static const Map<String, ({String category, List<String> siblings})> _appContext = {
    'TikTok': (category: 'Social', siblings: ['Instagram', 'Twitter']),
    'Instagram': (category: 'Social', siblings: ['TikTok', 'Twitter']),
    'Twitter': (category: 'Social', siblings: ['Instagram', 'TikTok']),
    'Facebook': (category: 'Social', siblings: ['Instagram', 'Twitter']),
    'Snapchat': (category: 'Social', siblings: ['Instagram', 'TikTok']),
    'YouTube': (category: 'Entertainment', siblings: ['Instagram', 'Twitter']),
  };

  ({String category, List<String> siblings}) get _context =>
      _appContext[widget.appName] ?? (category: 'Social', siblings: ['Instagram', 'X']);

  static const _categories = ['Social', 'Entertainment', 'Education'];

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    while (mounted) {
      await _go(_Step.sheetIn, const Duration(milliseconds: 500));
      await _go(_Step.categoryTap, const Duration(milliseconds: 700));
      await _go(_Step.categoryOpen, const Duration(milliseconds: 900));
      await _go(_Step.appTap, const Duration(milliseconds: 700));
      await _go(_Step.checked, const Duration(milliseconds: 900));
      await _go(_Step.saveTap, const Duration(milliseconds: 700));
      await _go(_Step.reset, const Duration(milliseconds: 900));
    }
  }

  Future<void> _go(_Step step, Duration hold) async {
    if (!mounted) return;
    setState(() => _step = step);
    if (step == _Step.categoryTap || step == _Step.appTap || step == _Step.saveTap) {
      HapticFeedback.lightImpact();
    }
    await Future.delayed(hold);
  }

  bool get _categoryExpanded =>
      _step == _Step.categoryOpen || _step == _Step.appTap || _step == _Step.checked || _step == _Step.saveTap;
  bool get _appSelected => _step == _Step.checked || _step == _Step.saveTap;
  bool get _showTapDot =>
      _step == _Step.categoryTap || _step == _Step.appTap || _step == _Step.saveTap;

  @override
  Widget build(BuildContext context) {
    final targetCategory = _context.category;
    final targetIndex = _categories.indexOf(targetCategory);
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark; // 👈 new — device-level, not app theme

    final navBg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final navBorder = isDark ? const Color(0xFF38383A) : const Color(0xFFDDDDE3);
    final linkColor = isDark ? const Color(0xFF4A9EFF) : const Color(0xFF3478F6);
    final titleColor = isDark ? Colors.white : Colors.black87;
    final listBg = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final rowBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final rowDivider = isDark ? const Color(0xFF2C2C2E) : Colors.transparent;
    final labelColor = isDark ? Colors.white : Colors.black87;
    final siblingLabelColor = isDark ? const Color(0xFFE5E5E7) : const Color(0xFF333333);
    final chevronColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8E);
    final radioBorder = isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC);

    return Container(
      width: 260,
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border(context), width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: navBg,
                    border: Border(bottom: BorderSide(color: navBorder, width: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cancel', style: _uiText(color: linkColor, size: 11)),
                      Text('Choose ${widget.appName}',
                          style: _uiText(color: titleColor, size: 11, weight: FontWeight.w700)),
                      Text('Save', style: _uiText(color: linkColor, size: 11, weight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: listBg,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      children: List.generate(_categories.length, (i) {
                        final isTarget = i == targetIndex;
                        return Column(
                          children: [
                            _categoryRow(_categories[i],
                                expanded: isTarget && _categoryExpanded,
                                rowBg: rowBg, labelColor: labelColor, chevronColor: chevronColor),
                            if (isTarget)
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 250),
                                crossFadeState:
                                _categoryExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                                firstChild: Column(
                                  children: [
                                    _appRow(_context.siblings[0], selected: false,
                                        rowBg: rowBg, labelColor: siblingLabelColor,
                                        radioBorder: radioBorder, divider: rowDivider),
                                    _appRow(widget.appName, selected: _appSelected, highlight: true,
                                        rowBg: rowBg, labelColor: siblingLabelColor,
                                        radioBorder: radioBorder, divider: rowDivider, checkColor: linkColor),
                                    _appRow(_context.siblings[1], selected: false,
                                        rowBg: rowBg, labelColor: siblingLabelColor,
                                        radioBorder: radioBorder, divider: rowDivider),
                                  ],
                                ),
                                secondChild: const SizedBox.shrink(),
                              ),
                            const SizedBox(height: 3),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              top: _tapDotTop(targetIndex),
              left: _tapDotLeft(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showTapDot ? 1 : 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.accent(context).withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent(context), width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _tapDotTop(int targetIndex) {
    final categoryTop = 55.0 + (45.0 * targetIndex);
    switch (_step) {
      case _Step.categoryTap:
        return categoryTop + 8.0; // 👈 nudge down, adjust the +8 as needed
      case _Step.appTap:
      case _Step.checked:
      return categoryTop + 76.5 + 8.0; // 👈 same nudge applied
      case _Step.saveTap:
        return 8.0;
      default:
        return categoryTop;
    }
  }

  double _tapDotLeft() {
    if (_step == _Step.saveTap) return 205.0;
    return 20.0;
  }

  Widget _categoryRow(String label, {
    required bool expanded,
    required Color rowBg,
    required Color labelColor,
    required Color chevronColor,
  }) {
    final categoryEmoji = switch (label) {
      'Social' => '💬',
      'Entertainment' => '🍿',
      'Education' => '🌍',
      _ => '📱',
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(categoryEmoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: _uiText(color: labelColor, size: 11, weight: FontWeight.w600))),
          AnimatedRotation(
            duration: const Duration(milliseconds: 250),
            turns: expanded ? 0.5 : 0,
            child: Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: chevronColor),
          ),
        ],
      ),
    );
  }

  Widget _appRow(String name, {
    required bool selected,
    bool highlight = false,
    required Color rowBg,
    required Color labelColor,
    required Color radioBorder,
    required Color divider,
    Color checkColor = const Color(0xFF3478F6),
  }) {
    final iconSpec = _appIcons[name];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(top: BorderSide(color: divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? checkColor : Colors.transparent,
              border: Border.all(
                color: selected ? checkColor : radioBorder,
                width: 1.5,
              ),
            ),
            child: selected ? const Icon(Icons.check_rounded, size: 11, color: Colors.white) : null,
          ),
          const SizedBox(width: 8),
          Container(
            width: 20,
            height: 20,
            decoration: iconSpec?.bg != null
                ? BoxDecoration(color: iconSpec!.bg, borderRadius: BorderRadius.circular(5))
                : null,
            child: iconSpec != null
                ? Padding(
              padding: EdgeInsets.all(iconSpec.bg != null ? 3 : 0),
              child: SvgPicture.asset(
                iconSpec.asset,
                colorFilter: ColorFilter.mode(iconSpec.color, BlendMode.srcIn),
              ),
            )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: _uiText(
              color: labelColor,
              size: 10.5,
              weight: highlight ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
  TextStyle _uiText({required Color color, required double size, FontWeight weight = FontWeight.w400}) {
    return TextStyle(color: color, fontSize: size, fontWeight: weight);
  }
}
/// Tiny inline text-style helper so this file has no external font dependency beyond
/// what's already used elsewhere in the app.
class GoogleFontsFallback {
  static TextStyle text({required Color color, required double size, FontWeight weight = FontWeight.w400}) {
    return TextStyle(color: color, fontSize: size, fontWeight: weight);
  }
}