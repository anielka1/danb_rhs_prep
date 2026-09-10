import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Decorative study cards, not an interactive preview or fabricated results.
/// Code-native geometry scales without asset downloads or animations.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: 190,
          width: double.infinity,
          child: CustomPaint(
            painter: _StudyCardsPainter(
              primary: context.colors.primary,
              pale: context.colors.primaryContainer,
              paper: context.colors.surfaceContainer,
              ink: context.colors.onSurface,
            ),
          ),
        ),
      );
}

class _StudyCardsPainter extends CustomPainter {
  const _StudyCardsPainter(
      {required this.primary,
      required this.pale,
      required this.paper,
      required this.ink});
  final Color primary, pale, paper, ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, 0);
    final scale = (size.width / 320).clamp(0.0, 1.0);
    canvas.scale(scale);
    final paint = Paint();
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 93), width: 300, height: 176),
        paint..color = pale);
    canvas.drawCircle(const Offset(126, 25), 13,
        paint..color = primary.withValues(alpha: 0.12));
    canvas.drawCircle(const Offset(-140, 141), 7,
        paint..color = primary.withValues(alpha: 0.25));
    canvas.save();
    canvas.translate(-82, 54);
    canvas.rotate(-0.15);
    final back = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 112, 118), const Radius.circular(23));
    canvas.drawRRect(back, paint..color = primary.withValues(alpha: 0.22));
    canvas.restore();
    canvas.save();
    canvas.translate(-29, 20);
    canvas.rotate(0.12);
    final card = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 145, 146), const Radius.circular(25));
    canvas.drawShadow(
        Path()..addRRect(card), primary.withValues(alpha: 0.18), 12, false);
    canvas.drawRRect(card, paint..color = paper);
    for (var i = 0; i < 3; i++) {
      final y = 39.0 + i * 33;
      canvas.drawCircle(Offset(27, y), 9, paint..color = pale);
      final tick = Path()
        ..moveTo(23, y)
        ..lineTo(26, y + 3)
        ..lineTo(32, y - 4);
      canvas.drawPath(
          tick,
          Paint()
            ..color = primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(46, y - 4, i == 1 ? 57 : 70, 7),
              const Radius.circular(4)),
          paint..color = ink.withValues(alpha: 0.13));
    }
    canvas.restore();
    final tile = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-118, 70, 87, 87), const Radius.circular(24));
    canvas.drawShadow(
        Path()..addRRect(tile), primary.withValues(alpha: 0.25), 10, false);
    canvas.drawRRect(tile, paint..color = primary);
    final book = Paint()
      ..color = paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
        Path()
          ..moveTo(-75, 97)
          ..quadraticBezierTo(-91, 88, -99, 94)
          ..lineTo(-99, 125)
          ..quadraticBezierTo(-85, 122, -75, 132)
          ..quadraticBezierTo(-64, 122, -51, 125)
          ..lineTo(-51, 94)
          ..quadraticBezierTo(-62, 89, -75, 97)
          ..lineTo(-75, 132),
        book);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StudyCardsPainter old) =>
      old.primary != primary ||
      old.pale != pale ||
      old.paper != paper ||
      old.ink != ink;
}
