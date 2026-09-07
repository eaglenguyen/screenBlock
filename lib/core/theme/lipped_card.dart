import 'package:flutter/material.dart';

import 'app_colors.dart';

class LippedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? lipColor;

  const LippedCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.lipColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 4,
          left: 6,
          right: 6,
          bottom: -8,
          child: Container(
            decoration: BoxDecoration(
              color: lipColor ?? AppColors.cardLip(context),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.backgroundCard(context),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}