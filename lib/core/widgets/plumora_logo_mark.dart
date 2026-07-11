import 'package:flutter/material.dart';

class PlumoraLogoMark extends StatelessWidget {
  const PlumoraLogoMark({
    this.size = 28,
    this.color = const Color(0xFF4B2E83),
    this.strokeWidth = 2.6,
    super.key,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _PlumoraLogoPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _PlumoraLogoPainter extends CustomPainter {
  const _PlumoraLogoPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Offset p(double x, double y) => Offset(x * scale, y * scale);

    final feather = Path()
      ..moveTo(20.24 * scale, 12.24 * scale)
      ..arcToPoint(
        p(11.75, 3.75),
        radius: Radius.circular(6 * scale),
        clockwise: false,
      )
      ..lineTo(5 * scale, 10.5 * scale)
      ..lineTo(5 * scale, 19 * scale)
      ..lineTo(13.5 * scale, 19 * scale)
      ..close();

    canvas.drawPath(feather, paint);
    canvas.drawLine(p(16, 8), p(2, 22), paint);
    canvas.drawLine(p(17.5, 15), p(9, 15), paint);
  }

  @override
  bool shouldRepaint(covariant _PlumoraLogoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
