import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Intentional, constrained size variants for [ReadinessRing] — callers
/// pick a purpose (a compact list row vs. a hero card), not an arbitrary
/// pixel size.
enum ReadinessRingSize { small, medium, large }

extension on ReadinessRingSize {
  double get diameter {
    switch (this) {
      case ReadinessRingSize.small:
        return 56;
      case ReadinessRingSize.medium:
        return 96;
      case ReadinessRingSize.large:
        return 140;
    }
  }

  double get strokeWidth {
    switch (this) {
      case ReadinessRingSize.small:
        return 5;
      case ReadinessRingSize.medium:
        return 9;
      case ReadinessRingSize.large:
        return 12;
    }
  }

  TextStyle labelStyle(TextStyle base) {
    switch (this) {
      case ReadinessRingSize.small:
        return base.copyWith(fontSize: 14, fontWeight: FontWeight.w800);
      case ReadinessRingSize.medium:
        return base.copyWith(fontSize: 22, fontWeight: FontWeight.w800);
      case ReadinessRingSize.large:
        return base.copyWith(fontSize: 32, fontWeight: FontWeight.w800);
    }
  }
}

/// A circular readiness/percentage indicator. This widget only draws a
/// score it is given — it never computes readiness itself, so it can be
/// reused anywhere a 0-100 value needs a consistent visual treatment.
///
/// Progress is communicated through the filled arc, the printed
/// percentage text, and accessibility value/label — never through color
/// alone.
class ReadinessRing extends StatelessWidget {
  ReadinessRing({
    super.key,
    required this.score,
    this.size = ReadinessRingSize.medium,
    this.hasEvidence = true,
    this.semanticLabel = 'Readiness score',
  }) {
    if (score < 0 || score > 100) {
      throw ArgumentError.value(score, 'score', 'must be between 0 and 100');
    }
  }

  /// 0-100. Always required, even when [hasEvidence] is false (pass 0 or
  /// the last-known value); [hasEvidence] alone controls the low-evidence
  /// presentation.
  final double score;

  final ReadinessRingSize size;

  /// When false, the ring renders in a muted "not enough data yet" style
  /// instead of implying a confident low score.
  final bool hasEvidence;

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final diameter = size.diameter;
    final trackColor = colors.outlineVariant;
    final progressColor =
        hasEvidence ? colors.primary : context.semanticColors.mutedForeground;

    return Semantics(
      label: semanticLabel,
      value: hasEvidence ? '${score.round()} percent' : 'Not enough data yet',
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(diameter),
              painter: _RingPainter(
                progress: hasEvidence ? score / 100 : 0,
                trackColor: trackColor,
                progressColor: progressColor,
                strokeWidth: size.strokeWidth,
                dashed: !hasEvidence,
              ),
            ),
            ExcludeSemantics(
              child: hasEvidence
                  ? Text('${score.round()}%',
                      style: size.labelStyle(context.textStyles.h1))
                  : Text(
                      '--',
                      style: size.labelStyle(
                        context.textStyles.h1.copyWith(
                            color: context.semanticColors.mutedForeground),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.dashed,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset center = rect.center;
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (dashed || progress <= 0) return;

    final Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const double startAngle = -math.pi / 2;
    final double sweepAngle = 2 * math.pi * progress.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashed != dashed;
  }
}
