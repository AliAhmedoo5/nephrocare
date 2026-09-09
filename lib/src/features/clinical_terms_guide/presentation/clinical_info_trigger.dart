import 'package:flutter/material.dart';

import '../domain/clinical_term.dart';
import 'caregiver_terms_guide_screen.dart';

/// Contextual info trigger button `(i)` embedded beside complex clinical indicators.
///
/// Meets WCAG AA accessibility standards with a guaranteed minimum 48dp touch target.
/// Tapping opens a modal bottom sheet displaying clear, non-technical explanations and safe ranges
/// without navigating away from the current clinical task.
class ClinicalInfoTrigger extends StatelessWidget {
  final String termId;
  final ClinicalTerm? term;
  final String? tooltip;
  final double iconSize;

  const ClinicalInfoTrigger({
    super.key,
    required this.termId,
    this.term,
    this.tooltip,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTerm = term ?? ClinicalTermsRegistry.getTermById(termId);
    if (resolvedTerm == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Clinical explanation for ${resolvedTerm.title}',
      hint: 'Double tap to open plain-language explanation and safe ranges',
      child: IconButton(
        icon: Icon(
          Icons.info_outline_rounded,
          size: iconSize,
          color: theme.colorScheme.primary,
        ),
        constraints: const BoxConstraints(
          minWidth: 48.0,
          minHeight: 48.0,
        ),
        tooltip: tooltip ?? 'Explain ${resolvedTerm.title}',
        onPressed: () {
          showClinicalContextualSheet(context, term: resolvedTerm);
        },
      ),
    );
  }
}

/// Displays a modal bottom sheet with plain-language explanation and safe ranges
/// for a clinical term without disrupting user workflow.
Future<void> showClinicalContextualSheet(
  BuildContext context, {
  required ClinicalTerm term,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      return Padding(
        key: const Key('clinical_contextual_bottom_sheet'),
        padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Title & Close Button (48dp min target)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          term.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            term.category.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('bottom_sheet_close_button'),
                    icon: const Icon(Icons.close_rounded),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    tooltip: 'Close explanation',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Plain Language Explanation Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plain-Language Explanation',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      term.plainLanguageDefinition,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Why It Matters
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Why It Matters',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      term.clinicalRelevance,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Safe Range or Target
              if (term.safeRangeOrTarget != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Safe Ranges & Clinical Targets',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              term.safeRangeOrTarget!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.35,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Actions: Open Full Guide & Done (Min 48dp height)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        key: const Key('bottom_sheet_open_full_guide_button'),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text(
                          'Full Terms Guide',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CaregiverTermsGuideScreen(
                                initialTermId: term.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        key: const Key('bottom_sheet_dismiss_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text(
                          'Got It',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
