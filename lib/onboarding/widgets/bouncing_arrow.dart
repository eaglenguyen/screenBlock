import 'package:flutter/material.dart';

class BouncingArrowUp extends StatefulWidget {
  final Color? color; // 👈 new — optional override

  const BouncingArrowUp({super.key, this.color});

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
        offset: Offset(0, -_anim.value),
        child: Icon(
          Icons.keyboard_arrow_up_rounded,
          color: widget.color ?? (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black), // 👈 wrapped the ternary in parens
          size: 40,
        ),
      ),
    );
  }
}