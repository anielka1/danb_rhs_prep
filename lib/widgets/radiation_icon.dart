import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Outline radiation trefoil symbol drawn to match the splash screen icon.
class RadiationIcon extends StatelessWidget {
  final double size;
  final Color color;

  const RadiationIcon({super.key, this.size = 44, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadiationPainter(color: color),
      ),
    );
  }
}

class _RadiationPainter extends CustomPainter {
  final Color color;
  _RadiationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerR = size.width * 0.46;
    final double innerR = size.width * 0.14;
    final double petalSpan = size.width * 0.30;

    for (int i = 0; i < 3; i++) {
      final double angle = -math.pi / 2 + i * (2 * math.pi / 3);
      final Offset tip = center + Offset(math.cos(angle), math.sin(angle)) * outerR;
      final Offset a = center + Offset(math.cos(angle - 0.42), math.sin(angle - 0.42)) * innerR;
      final Offset b = center + Offset(math.cos(angle + 0.42), math.sin(angle + 0.42)) * innerR;
      final Offset tipLeft = tip + Offset(math.cos(angle + math.pi / 2), math.sin(angle + math.pi / 2)) * (petalSpan * 0.28);
      final Offset tipRight = tip + Offset(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2)) * (petalSpan * 0.28);

      final Path path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(tipLeft.dx, tipLeft.dy)
        ..lineTo(tipRight.dx, tipRight.dy)
        ..lineTo(b.dx, b.dy)
        ..close();
      canvas.drawPath(path, stroke);
    }

    canvas.drawCircle(center, innerR * 0.9, stroke);
  }

  @override
  bool shouldRepaint(covariant _RadiationPainter oldDelegate) => oldDelegate.color != color;
}
