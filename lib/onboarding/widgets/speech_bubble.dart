import 'package:flutter/cupertino.dart';

class SpeechBubbleWithTail extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;

  const SpeechBubbleWithTail({
    super.key,
    required this.child,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(color: color, borderColor: borderColor),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12), // 👈 reserves space for the tail below the bubble
        child: child,
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _BubbleTailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final tailWidth = 20.0;
    final tailHeight = 14.0;
    final centerX = size.width / 2;
    final bubbleBottom = size.height - tailHeight;

    final path = Path()
      ..moveTo(centerX - tailWidth / 2, bubbleBottom)
      ..lineTo(centerX, size.height)
      ..lineTo(centerX + tailWidth / 2, bubbleBottom)
      ..close();

    final fillPaint = Paint()..color = color;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => false;
}