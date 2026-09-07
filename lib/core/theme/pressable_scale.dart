// lib/core/theme/widgets/pressable_scale.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressScale;
  final Offset pressOffset;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressScale = 0.95,
    this.pressOffset = const Offset(0, 4), // 👈 matches the lip's offset feel
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    setState(() => _isPressed = pressed);
    if (pressed) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_isPressed ? widget.pressScale : 1.0)
          ..translate(0.0, _isPressed ? widget.pressOffset.dy : 0.0),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}