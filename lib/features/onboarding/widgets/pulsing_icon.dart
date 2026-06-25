import 'package:flutter/cupertino.dart';

class PulsingIcon extends StatefulWidget {
  final String emoji;
  const PulsingIcon({required this.emoji});

  @override
  State<PulsingIcon> createState() => PulsingIconState();
}

class PulsingIconState extends State<PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
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
      animation: _pulse,
      builder: (_, __) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFEDB82A).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFEDB82A)
                .withValues(alpha: 0.2 + 0.4 * _pulse.value),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEDB82A)
                  .withValues(alpha: 0.1 + 0.25 * _pulse.value),
              blurRadius: 8 + 16 * _pulse.value,
              spreadRadius: 1 + 4 * _pulse.value,
            ),
          ],
        ),
        child: Center(
          child: Text(widget.emoji, style: const TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}