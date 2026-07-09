
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoldToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;

  const HoldToConfirmButton({super.key, required this.onConfirmed});

  @override
  State<HoldToConfirmButton> createState() => HoldToConfirmButtonState();
}

class HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    setState(() => _holding = true);
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(_) => _cancel();
  void _onTapCancel() => _cancel();

  void _cancel() {
    setState(() => _holding = false);
    _controller.reverse();
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
              color: Colors.orange,
              borderRadius: BorderRadius.circular(50),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // fill progress
                FractionallySizedBox(
                  widthFactor: _controller.value,
                  child: Container(
                    color: Colors.orange.shade800,
                  ),
                ),
                // label
                Center(
                  child: Text(
                    _holding
                        ? 'Keep holding...'
                        : 'Hold to Pause',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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