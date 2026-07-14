import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoldToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final Color color;
  final Color fillColor;
  final Color textColor;
  final String label;
  final String holdingLabel;
  final String doneLabel;
  final Duration holdDuration;

  const HoldToConfirmButton({
    super.key,
    required this.onConfirmed,
    this.color = Colors.orange,
    this.fillColor = const Color(0xFFE65100),
    this.textColor = Colors.black,
    this.label = 'Hold to Pause',
    this.holdingLabel = 'Keep holding...',
    this.doneLabel = 'Pausing',
    this.holdDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<HoldToConfirmButton> createState() => HoldToConfirmButtonState();
}

class HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _holding = false;
  bool _completed = false;
  Timer? _hapticTimer;
  int _hapticTick = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hapticTimer?.cancel();
    super.dispose();
  }

  void _onTapDown(_) {
    if (_completed) return;
    setState(() => _holding = true);
    HapticFeedback.lightImpact();
    _controller.forward();
    _startEscalatingHaptics();
  }

  void _onTapUp(_) => _cancel();
  void _onTapCancel() => _cancel();

  void _cancel() {
    if (_completed) return;
    setState(() => _holding = false);
    _controller.reverse();
    _hapticTimer?.cancel();
    _hapticTick = 0;
  }

  // 👇 escalating haptic — starts light, gets stronger and more frequent
  // the longer the hold continues, simulating increasing intensity
  void _startEscalatingHaptics() {
    _hapticTick = 0;
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      _hapticTick++;
      final progress = _controller.value;

      if (progress >= 1.0) {
        timer.cancel();
        return;
      }

      if (progress < 0.4) {
        HapticFeedback.selectionClick();
      } else if (progress < 0.75) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  Future<void> _onHoldComplete() async {
    _hapticTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _holding = false;
      _completed = true;
    });

    // brief pause on "Done" before actually confirming/exiting
    await Future.delayed(const Duration(milliseconds: 450));
    if (mounted) widget.onConfirmed();
  }

  String get _currentLabel {
    if (_completed) return widget.doneLabel;
    if (_holding) return widget.holdingLabel;
    return widget.label;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(50),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: _controller.value,
                  child: Container(
                    color: widget.fillColor
                  ),
                ),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(_currentLabel),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_completed) ...[
                          Icon(Icons.check_rounded, color: widget.textColor, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _currentLabel,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}