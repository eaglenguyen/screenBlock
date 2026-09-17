import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingContinueButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final bool enabled;

  const OnboardingContinueButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF7DD3B0), // app's mint accent
    this.textColor = const Color(0xFF0F4A32), // accent text
    this.enabled = true,
  });

  @override
  State<OnboardingContinueButton> createState() => _OnboardingContinueButtonState();
}

class _OnboardingContinueButtonState extends State<OnboardingContinueButton> {
  bool _isPressed = false;
  bool _isLocked = false; // 👈 new

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onTap == null || _isLocked) return; // 👈 guard added
    setState(() => _isPressed = true);
    HapticFeedback.mediumImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled || widget.onTap == null || _isLocked) return; // 👈 guard added
    setState(() => _isPressed = false);
    _isLocked = true; // 👈 new — locks immediately on tap
    widget.onTap!();
    Future.delayed(const Duration(milliseconds: 600), () { // 👈 new — unlocks after a beat, in case the button is reused without rebuilding
      if (mounted) _isLocked = false;
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final lipColor = Color.lerp(widget.color, Colors.black, 0.18)!; // darker "lip" shade beneath

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: SizedBox(
          width: double.infinity,
          height: 64, // total height includes room for the lip
          child: Stack(
            children: [
              // the lip — fixed at the bottom, never moves
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: lipColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              // the top face — slides down to meet the lip when pressed
              AnimatedPositioned(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: _isPressed ? 6 : 0, // 👈 pushes down into the lip on press
                bottom: _isPressed ? 0 : 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}