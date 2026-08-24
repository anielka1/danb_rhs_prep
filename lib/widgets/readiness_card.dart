import 'package:flutter/material.dart';
import '../domain/models/readiness_band.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'readiness_ring.dart';

/// Home/Progress-style summary card: a [ReadinessRing] plus the band
/// label, an optional evidence-confidence explanation, an optional
/// supporting message, and an optional "view detail" affordance.
///
/// Reuses the domain [ReadinessBand] enum for its label rather than
/// duplicating readiness vocabulary, and performs no readiness math of
/// its own — every value is supplied by the caller.
class ReadinessCard extends StatelessWidget {
  const ReadinessCard({
    super.key,
    required this.score,
    required this.band,
    this.hasEvidence = true,
    this.evidenceExplanation,
    this.supportingMessage,
    this.onViewDetail,
  });

  final double score;
  final ReadinessBand band;
  final bool hasEvidence;

  /// e.g. "Based on 12 recent questions — estimate will firm up as you
  /// answer more."
  final String? evidenceExplanation;

  /// e.g. "Radiation Protection has 3 recent mistakes."
  final String? supportingMessage;

  final VoidCallback? onViewDetail;

  static const Map<ReadinessBand, String> _bandLabels = {
    ReadinessBand.starting: 'Starting',
    ReadinessBand.developing: 'Developing',
    ReadinessBand.gettingClose: 'Getting Close',
    ReadinessBand.examReady: 'Exam Ready',
    ReadinessBand.stronglyPrepared: 'Strongly Prepared',
  };

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final String bandLabel =
        hasEvidence ? _bandLabels[band]! : 'Not enough data yet';

    // Note: no card-level `semanticLabel` here. AppCard's semanticLabel
    // mechanism excludes the *entire* child from the semantics tree and
    // replaces it with one label — correct for a card that's a single
    // logical control, but wrong here: "View Details" is an independent,
    // separately-actionable control, and excluding it entirely would make
    // it unreachable by VoiceOver. Instead: the ring keeps its own
    // existing semantics (score/value), the band label/explanation/
    // supporting message are combined into one adjacent announcement
    // below, and the button remains a normal, independently-reachable
    // sibling — never nested inside an ExcludeSemantics region.
    final String textSummary = hasEvidence
        ? '$bandLabel'
            '${evidenceExplanation != null ? '. $evidenceExplanation' : ''}'
            '${supportingMessage != null ? '. $supportingMessage' : ''}'
        : 'Not enough data yet';

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ReadinessRing(score: score, hasEvidence: hasEvidence),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: textSummary,
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(bandLabel, style: textStyles.h3),
                        if (evidenceExplanation != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(evidenceExplanation!,
                              style: textStyles.bodySmall),
                        ],
                        if (supportingMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(supportingMessage!, style: textStyles.body),
                        ],
                      ],
                    ),
                  ),
                ),
                if (onViewDetail != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onViewDetail,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Semantics(
                        label: 'View readiness detail',
                        child: ExcludeSemantics(
                          child: Text(
                            'View Details',
                            style: textStyles.bodySmall.copyWith(
                              color: context.colors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
