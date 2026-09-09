import 'package:flutter/material.dart';

import '../../catheter/domain/catheter_lifespan_rules.dart';
import '../../fluid/domain/fluid_balance_summary.dart';
import '../../profile/domain/condition_adaptive_grid_config.dart';

/// Renders the Condition-Adaptive Grid presenting exactly six uncluttered,
/// high-contrast clinical action cards tailored to the active condition per CONTEXT.md.
class ConditionAdaptiveGrid extends StatelessWidget {
  final String conditionName;
  final void Function(ClinicalActionCard card)? onCardTap;
  final FluidBalanceSummary? fluidSummary;
  final CatheterLifespanSummary? catheterSummary;

  const ConditionAdaptiveGrid({
    super.key,
    required this.conditionName,
    this.onCardTap,
    this.fluidSummary,
    this.catheterSummary,
  });

  @override
  Widget build(BuildContext context) {
    final cards = ConditionAdaptiveGridConfig.getCardsForCondition(conditionName);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: constraints.maxWidth > 400 ? 1.15 : 0.95,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            var effectiveCard = card;

            if (fluidSummary != null) {
              if (card.id == 'hd_fluid_intake' || card.id == 'ckd_fluid_allowance' || card.id == 'uro_fluid_intake') {
                effectiveCard = ClinicalActionCard(
                  id: card.id,
                  title: card.title,
                  subtitle: fluidSummary!.formattedIntakeProgression,
                  icon: card.icon,
                  semanticLabel: card.semanticLabel,
                  accentColor: card.accentColor,
                );
              } else if (card.id == 'hd_fluid_output' || card.id == 'uro_urine_evacuation') {
                effectiveCard = ClinicalActionCard(
                  id: card.id,
                  title: card.title,
                  subtitle: fluidSummary!.formattedOutputWithNet,
                  icon: card.icon,
                  semanticLabel: card.semanticLabel,
                  accentColor: card.accentColor,
                );
              } else if (card.id == 'pd_fluid_balance') {
                effectiveCard = ClinicalActionCard(
                  id: card.id,
                  title: card.title,
                  subtitle: fluidSummary!.formattedNetBalance24h,
                  icon: card.icon,
                  semanticLabel: card.semanticLabel,
                  accentColor: card.accentColor,
                );
              }
            }

            if (catheterSummary != null && card.id == 'uro_catheter_lifespan') {
              effectiveCard = ClinicalActionCard(
                id: card.id,
                title: card.title,
                subtitle: 'Day ${catheterSummary!.dayOfCycle} of ${catheterSummary!.totalLifespanDays} • ${catheterSummary!.statusTitle}',
                icon: card.icon,
                semanticLabel: card.semanticLabel,
                accentColor: catheterSummary!.statusColor,
              );
            }
            return _ClinicalActionGridCard(
              card: effectiveCard,
              theme: theme,
              onTap: () {
                if (onCardTap != null) {
                  onCardTap!(effectiveCard);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening ${card.title}...'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Accessible clinical card widget with high-contrast borders and min 48dp touch targets.
class _ClinicalActionGridCard extends StatelessWidget {
  final ClinicalActionCard card;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ClinicalActionGridCard({
    required this.card,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = theme.colorScheme.outline;

    return Semantics(
      label: card.semanticLabel,
      button: true,
      enabled: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 48.0,
                minWidth: 48.0,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon Container
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        card.icon,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Title and Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
