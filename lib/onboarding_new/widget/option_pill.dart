// lib/onboarding_new/widgets/onboarding_option_pill.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingOptionPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon; // 👈 new

  const OnboardingOptionPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon
  });

  @override
  State<OnboardingOptionPill> createState() => _OnboardingOptionPillState();
}

class _OnboardingOptionPillState extends State<OnboardingOptionPill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: widget.icon != null ? 20 : 0), // 👈 new — horizontal padding when icon present
          decoration: BoxDecoration(
            color: widget.isSelected ? const Color(0xFF7DD3B0).withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: widget.isSelected ? const Color(0xFF2D7A54) : const Color(0xFFF0E6D8),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: widget.icon != null
              ? Row( // 👈 new — icon + centered label
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected ? const Color(0xFF2D7A54) : const Color(0xFFB08A5A),
              ),
              Expanded(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.isSelected ? const Color(0xFF2D7A54) : const Color(0xFF4A3728),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 20), // 👈 balances the icon's width so text stays visually centered
            ],
          )
              : Center( // 👈 original layout, unchanged, when no icon
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.isSelected ? const Color(0xFF2D7A54) : const Color(0xFF4A3728),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}