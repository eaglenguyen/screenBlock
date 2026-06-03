import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Staggered entrance animation mixin ───────────────
// Add to any onboarding screen State class
// Usage:
//   class _MyScreenState extends State<MyScreen>
//       with SingleTickerProviderStateMixin, OnboardingEntranceMixin

mixin OnboardingEntranceMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {

  late AnimationController entranceController;
  late List<Animation<double>> fadeAnims;
  late List<Animation<Offset>> slideAnims;

  // call in initState with how many elements to stagger
  void initEntrance({int elementCount = 4}) {
    entranceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (elementCount * 80)),
    );

    fadeAnims = List.generate(elementCount, (i) {
      final start = i * 0.12;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: entranceController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    slideAnims = List.generate(elementCount, (i) {
      final start = i * 0.12;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: entranceController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    entranceController.forward();
  }

  void disposeEntrance() {
    entranceController.dispose();
  }

  // wrap any widget with this to animate it in
  Widget staggered(int index, Widget child) {
    if (index >= fadeAnims.length) return child;
    return FadeTransition(
      opacity: fadeAnims[index],
      child: SlideTransition(
        position: slideAnims[index],
        child: child,
      ),
    );
  }
}

// ── Shimmer button ────────────────────────────────────

class ShimmerButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;

  const ShimmerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.backgroundColor = const Color(0xFFEDB82A),
    this.textColor = const Color(0xFF1A1208),
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {

  bool _pressed = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  // outer wide glow — pulses
                  BoxShadow(
                    color: widget.backgroundColor.withValues(
                      alpha: _pressed ? 0.2 : _pulseAnim.value,
                    ),
                    blurRadius: _pressed ? 8 : 28,
                    spreadRadius: _pressed ? 0 : 6,
                    offset: const Offset(0, 4),
                  ),
                  // inner tight glow — always visible
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  color: widget.textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated option card ──────────────────────────────

class AnimatedOptionCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;

  const AnimatedOptionCard({
    super.key,
    required this.child,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = const Color(0xFFEDB82A),
  });

  @override
  State<AnimatedOptionCard> createState() => _AnimatedOptionCardState();
}

class _AnimatedOptionCardState extends State<AnimatedOptionCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _glowAnim = CurvedAnimation(
      parent: _glowCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(AnimatedOptionCard old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _glowCtrl.forward();
    } else if (!widget.isSelected && old.isSelected) {
      _glowCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : widget.isSelected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.selectedColor
                              .withValues(alpha: 0.25 * _glowAnim.value),
                          blurRadius: 12 * _glowAnim.value,
                          spreadRadius: 1 * _glowAnim.value,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.selectedColor.withValues(alpha: 0.1)
                  : const Color(0xFF1E1E35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? widget.selectedColor.withValues(alpha: 0.6)
                    : const Color(0xFF2A2A48),
                width: widget.isSelected ? 1.5 : 0.5,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ── Animated checkmark ────────────────────────────────

class AnimatedCheckmark extends StatefulWidget {
  final bool visible;
  final Color color;
  final Color iconColor;

  const AnimatedCheckmark({
    super.key,
    required this.visible,
    this.color = const Color(0xFFEDB82A),
    this.iconColor = const Color(0xFF1A1208),
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    if (widget.visible) _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCheckmark old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _ctrl.forward();
    } else if (!widget.visible && old.visible) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: widget.iconColor,
          size: 15,
        ),
      ),
    );
  }
}

// ── Gold highlighted text helper ──────────────────────
// Usage: GoldText(text: 'Choose a', goldWord: 'username')

class GoldText extends StatelessWidget {
  final String text;
  final String goldWord;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  const GoldText({
    super.key,
    required this.text,
    required this.goldWord,
    this.fontSize = 34,
    this.fontWeight = FontWeight.w900,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final parts = text.split(goldWord);
    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: -1,
          height: 1.15,
        ),
        children: [
          if (parts[0].isNotEmpty) TextSpan(text: parts[0]),
          TextSpan(
            text: goldWord,
            style: GoogleFonts.poppins(
              color: const Color(0xFFEDB82A),
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: -1,
            ),
          ),
          if (parts.length > 1 && parts[1].isNotEmpty)
            TextSpan(text: parts[1]),
        ],
      ),
    );
  }
}
