// lib/core/widgets/lipped_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LippedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? lipColor; // defaults to a darker shade of `color` if not provided
  final double height;
  final double lipDepth;
  final BorderRadius? borderRadius;
  final bool enabled;

  const LippedButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    this.lipColor,
    this.height = 58,
    this.lipDepth = 6,
    this.borderRadius,
    this.enabled = true,
  });

  @override
  State<LippedButton> createState() => _LippedButtonState();
}

class _LippedButtonState extends State<LippedButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = true);
    HapticFeedback.mediumImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = false);
    widget.onTap!();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(50);
    final lip = widget.lipColor ?? Color.lerp(widget.color, Colors.black, 0.18)!;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: SizedBox(
          width: double.infinity,
          height: widget.height + widget.lipDepth,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(color: lip, borderRadius: radius),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: _isPressed ? widget.lipDepth : 0,
                bottom: _isPressed ? 0 : widget.lipDepth,
                child: Container(
                  decoration: BoxDecoration(color: widget.color, borderRadius: radius),
                  child: Center(child: widget.child),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}