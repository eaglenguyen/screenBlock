import 'package:flutter/material.dart';

class BouncingArrow extends StatefulWidget {
  const BouncingArrow({super.key});

  @override
  State<BouncingArrow> createState() => BouncingArrowState();
}

class BouncingArrowState extends State<BouncingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 6).animate(
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
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: const Color(0xFFEDB82A).withValues(alpha: 0.8),
          size: 32,
        ),
      ),
    );
  }
}


class BouncingArrowUp extends StatefulWidget {
  const BouncingArrowUp({super.key});

  @override
  State<BouncingArrowUp> createState() => BouncingArrowUpState();
}

class BouncingArrowUpState extends State<BouncingArrowUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 4).animate(
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
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -_anim.value), // 👈 bounces up toward button
        child: Icon(
          Icons.keyboard_arrow_up_rounded, // 👈 points up at button
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}