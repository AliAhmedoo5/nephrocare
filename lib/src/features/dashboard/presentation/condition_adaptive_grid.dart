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
  final int? activeMedicationsCount;
  final bool hasActiveDialysisSession;

  const ConditionAdaptiveGrid({
    super.key,
    required this.conditionName,
    this.onCardTap,
    this.fluidSummary,
    this.catheterSummary,
    this.activeMedicationsCount,
    this.hasActiveDialysisSession = false,
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

            // 1. Fluid balance progression dynamic subtitle tailored per condition
            if (fluidSummary != null) {
              if (card.id == 'hd_fluid_hub' || (card.title == 'Fluid Hub' && conditionName == 'hemodialysis')) {
                effectiveCard = ClinicalActionCard(
                  id: card.id,
                  title: card.title,
                  subtitle: fluidSummary!.plainLanguageSummary,
                  icon: card.icon,
                  semanticLabel:
                      'Fluid Hub: 24-hour intake ${fluidSummary!.totalIntakeMl} mL, urine output ${fluidSummary!.totalUrineOutputMl} mL, dialysis removal ${fluidSummary!.machineUltrafiltrationMl} mL, net balance ${fluidSummary!.dialyticFluidBalanceMl >= 0 ? "+" : ""}${fluidSummary!.dialyticFluidBalanceMl} mL',
                  accentColor: card.accentColor,
                );
              } else if (card.id == 'ckd_fluid_hub') {
                final ckdSubtitle = fluidSummary!.dailyFluidAllowanceMl != null
                    ? '${fluidSummary!.formattedIntakeProgression} • Net: ${fluidSummary!.nativeUrineBalanceMl >= 0 ? '+' : ''}${fluidSummary!.nativeUrineBalanceMl} mL'
                    : 'Intake: ${fluidSummary!.totalIntakeMl} mL • Urine: ${fluidSummary!.totalUrineOutputMl} mL';
                effectiveCard = ClinicalActionCard(
                  id: card.id,
                  title: card.title,
                  subtitle: ckdSubtitle,
                  icon: card.icon,
                  semanticLabel: 'Fluid Hub: $ckdSubtitle',
                  accentColor: card.accentColor,
                );
              } else if (card.id == 'uro_fluid_hub') {
                final uroSubtitle = fluidSummary!.dailyFluidAllowanceMl != null
                    ? '${fluidSummary!.formattedIntakeProgression} • Urine: ${fluidSummary!.totalUrineOutputMl} mL'
                    : 'Intake: ${fluidSummary!.totalIntakeMl} mL • Output: ${fluidSummary!.totalUrineOutputMl} mL';
                effectiveCard = ClinicalActionCard(
                  id: card.id,
                  title: card.title,
                  subtitle: uroSubtitle,
                  icon: card.icon,
                  semanticLabel: 'Fluid Hub: $uroSubtitle',
                  accentColor: card.accentColor,
                );
              } else if (card.id == 'pd_fluid_hub') {
                final pdSubtitle = fluidSummary!.dailyFluidAllowanceMl != null
                    ? '${fluidSummary!.formattedIntakeProgression} • ${fluidSummary!.formattedNetBalance24h}'
                    : fluidSummary!.formattedNetBalance24h;
                effectiveCard = ClinicalActionCard(
                  id: card.id,
                  title: card.title,
                  subtitle: pdSubtitle,
                  icon: card.icon,
                  semanticLabel: 'Fluid Hub: $pdSubtitle',
                  accentColor: card.accentColor,
                );
              } else if (card.id.contains('fluid_hub') || card.title == 'Fluid Hub') {
                effectiveCard = ClinicalActionCard(
                  id: card.id,
                  title: card.title,
                  subtitle: fluidSummary!.formattedIntakeProgression,
                  icon: card.icon,
                  semanticLabel: 'Fluid Hub: ${fluidSummary!.formattedIntakeProgression}',
                  accentColor: card.accentColor,
                );
              }
            }

            // 2. Catheter risk state dynamic subtitle
            // Strictly scoped to urinary Foley catheter lifespans (14-day CAUTI cycle),
            // NOT vascular hemodialysis access (which monitors thrill, bruit & lines).
            if (catheterSummary != null) {
              if (card.id == 'uro_catheter_lifespan' ||
                  card.title == 'Foley Catheter Lifespan') {
                effectiveCard = ClinicalActionCard(
                  id: card.id,
                  title: card.title,
                  subtitle: 'Day ${catheterSummary!.dayOfCycle} of ${catheterSummary!.totalLifespanDays} • ${catheterSummary!.statusTitle}',
                  icon: card.icon,
                  semanticLabel: '${card.semanticLabel}: Day ${catheterSummary!.dayOfCycle} of ${catheterSummary!.totalLifespanDays}, ${catheterSummary!.statusTitle}',
                  accentColor: catheterSummary!.statusColor,
                );
              }
            }

            // 3. Active medications count dynamic subtitle
            if (activeMedicationsCount != null && (card.id.contains('medication') || card.title == 'Medication Management')) {
              effectiveCard = ClinicalActionCard(
                id: card.id,
                title: card.title,
                subtitle: activeMedicationsCount! > 0
                    ? '$activeMedicationsCount active medication${activeMedicationsCount == 1 ? '' : 's'} & binders'
                    : 'Regimen, phosphate binders & 1-tap doses',
                icon: card.icon,
                semanticLabel: '${card.semanticLabel}: $activeMedicationsCount active medications',
                accentColor: card.accentColor,
              );
            }

            // 4. Active dialysis session dynamic subtitle
            if (hasActiveDialysisSession && (card.id == 'hd_dialysis_session' || card.title == 'Unified Dialysis Session')) {
              effectiveCard = ClinicalActionCard(
                id: card.id,
                title: card.title,
                subtitle: 'Session in progress • Tap to resume/checkout',
                icon: card.icon,
                semanticLabel: '${card.semanticLabel}: Session currently in progress',
                accentColor: theme.colorScheme.primary,
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
  final VoidCallback? onTap;

  const _ClinicalActionGridCard({
    required this.card,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = card.accentColor ?? theme.colorScheme.outline;
    final borderWidth = card.accentColor != null ? 2.0 : 1.5;
    final iconBgColor = card.accentColor != null
        ? card.accentColor!.withValues(alpha: 0.15)
        : theme.colorScheme.primaryContainer;
    final iconColor = card.accentColor ?? theme.colorScheme.primary;

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
                width: borderWidth,
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
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        card.icon,
                        color: iconColor,
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
