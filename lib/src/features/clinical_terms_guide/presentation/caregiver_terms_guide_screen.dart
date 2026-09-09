import 'package:flutter/material.dart';

import '../domain/clinical_term.dart';

/// Dedicated screen rendering searchable, categorized medical and clinical term
/// definitions in accessible, plain language for attendants and family caregivers.
class CaregiverTermsGuideScreen extends StatefulWidget {
  final String? initialTermId;

  const CaregiverTermsGuideScreen({
    super.key,
    this.initialTermId,
  });

  @override
  State<CaregiverTermsGuideScreen> createState() => _CaregiverTermsGuideScreenState();
}

class _CaregiverTermsGuideScreenState extends State<CaregiverTermsGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  ClinicalTermCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });

    if (widget.initialTermId != null) {
      final initialTerm = ClinicalTermsRegistry.getTermById(widget.initialTermId!);
      if (initialTerm != null) {
        _selectedCategory = initialTerm.category;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTerms = ClinicalTermsRegistry.search(
      _searchQuery,
      category: _selectedCategory,
    );

    if (widget.initialTermId != null && _searchQuery.isEmpty) {
      final initialIdx = filteredTerms.indexWhere((t) => t.id == widget.initialTermId);
      if (initialIdx > 0) {
        final initial = filteredTerms.removeAt(initialIdx);
        filteredTerms.insert(0, initial);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Caregiver & Clinical Terms Guide',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              color: theme.colorScheme.surface,
              child: Column(
                children: [
                  TextField(
                    key: const Key('search_terms_input'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search terms, concepts, or indicators...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              key: const Key('clear_search_button'),
                              icon: const Icon(Icons.clear_rounded),
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category Filter Chips (Horizontal Scrollable)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            key: const Key('category_chip_all'),
                            label: const Text('All Concepts'),
                            selected: _selectedCategory == null,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = null;
                              });
                            },
                          ),
                        ),
                        ...ClinicalTermCategory.values.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              key: Key('category_chip_${category.name}'),
                              label: Text(category.displayName),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = isSelected ? null : category;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Term Count & Results List
            Expanded(
              child: filteredTerms.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No matching clinical terms found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try adjusting your search terms or clearing the category filter.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      itemCount: filteredTerms.length,
                      itemBuilder: (context, index) {
                        final term = filteredTerms[index];
                        final isHighlighted = widget.initialTermId == term.id;

                        return _ClinicalTermCard(
                          key: Key('guide_term_card_${term.id}'),
                          term: term,
                          isHighlighted: isHighlighted,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicalTermCard extends StatelessWidget {
  final ClinicalTerm term;
  final bool isHighlighted;

  const _ClinicalTermCard({
    super.key,
    required this.term,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
      color: isHighlighted
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isHighlighted ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: isHighlighted ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Category Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    term.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    term.category.displayName,
                    style: TextStyle(
                      fontSize: 10,
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
            const SizedBox(height: 10),

            // Plain Language Definition
            Text(
              term.plainLanguageDefinition,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Why It Matters Section
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Why It Matters for Patient Safety',
                        style: theme.textTheme.labelMedium?.copyWith(
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

            // Safe Range or Clinical Target
            if (term.safeRangeOrTarget != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Safe Range / Target: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: term.safeRangeOrTarget!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Terms to Avoid (per CONTEXT.md)
            if (term.avoidTerms.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Avoid confusion with:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  ...term.avoidTerms.map(
                    (avoid) => Text(
                      '• $avoid',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
