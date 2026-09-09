import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/dialysis_session_repository.dart';

/// Screen presenting the longitudinal comparison between Pre-Dialysis Weight,
/// Post-Dialysis Weight, and Prescribed Dry Weight to identify fluid accumulation trends,
/// alongside a daily weight logging form per CONTEXT.md and User Story 32.
class WeightTrendsScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const WeightTrendsScreen({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<WeightTrendsScreen> createState() => _WeightTrendsScreenState();
}

class _WeightTrendsScreenState extends ConsumerState<WeightTrendsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitWeight() async {
    if (!_formKey.currentState!.validate()) return;
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(dialysisSessionRepositoryProvider);
      await repo.recordDailyWeight(
        patientId: widget.patient.id,
        weightKg: weight,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        recordedAt: DateTime.now().toUtc(),
      );

      if (mounted) {
        _weightController.clear();
        _notesController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight logged: $weight kg.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving weight: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dryWeight = widget.patient.prescribedDryWeightKg;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weight Tracking & Trends',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Prescribed Dry Weight Target Overview
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monitor_weight_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Prescribed Clinical Target',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Prescribed Dry Weight:'),
                          Text(
                            dryWeight != null ? '$dryWeight kg' : 'Not set',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target body weight at the end of dialysis with zero fluid excess and normal hemodynamics.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Weight Logging Form
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Record Body Weight',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('daily_weight_input'),
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Body Weight (kg) *',
                            hintText: 'e.g. 71.4',
                            prefixIcon: Icon(Icons.scale_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter body weight';
                            }
                            final parsed = double.tryParse(val.trim());
                            if (parsed == null || parsed <= 0 || parsed > 300) {
                              return 'Enter a valid body weight (1 - 300 kg)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('daily_weight_notes_input'),
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            hintText: 'e.g. Morning fasting, post-dialysis, peripheral edema',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            key: const Key('save_weight_button'),
                            onPressed: _isSubmitting ? null : _submitWeight,
                            icon: const Icon(Icons.save_rounded),
                            label: Text(_isSubmitting ? 'Saving...' : 'Save Weight Log'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Longitudinal Weight Trends (User Story 32)
              Text(
                'Longitudinal Weight Comparison & Trends',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Comparing pre-dialysis weight, post-dialysis weight, and Prescribed Dry Weight across treatments:',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),

              _LongitudinalWeightList(patient: widget.patient),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reactive list comparing pre/post weights against Prescribed Dry Weight.
class _LongitudinalWeightList extends ConsumerWidget {
  final Patient patient;

  const _LongitudinalWeightList({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(dialysisSessionsStreamProvider(patient.id));
    final theme = Theme.of(context);
    final dryWeight = patient.prescribedDryWeightKg;

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No weight records logged yet.')),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final session = sessions[index];
            final dateStr =
                '${session.startedAt.year}-${session.startedAt.month.toString().padLeft(2, '0')}-${session.startedAt.day.toString().padLeft(2, '0')} ${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')}';

            final preWeight = session.preWeightKg;
            final postWeight = session.postWeightKg;
            final idwg = session.calculatedInterdialyticWeightGainKg;
            final ufRemoved = session.actualFluidRemovedMl;

            double? varianceFromDryWeight;
            if (postWeight != null && dryWeight != null) {
              varianceFromDryWeight = postWeight - dryWeight;
            } else if (preWeight != null && dryWeight != null) {
              varianceFromDryWeight = preWeight - dryWeight;
            }

            final isExcessiveGain = (idwg != null && idwg > 3.0) ||
                (varianceFromDryWeight != null && varianceFromDryWeight > 2.0);

            return Card(
              key: Key('weight_card_${session.id}'),
              elevation: 0,
              color: isExcessiveGain
                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
                  : theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isExcessiveGain ? theme.colorScheme.error : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(
                            session.sessionType == 'daily_weight' ? 'Daily Weight' : 'Dialysis Session',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (preWeight != null)
                          _Metric(
                            label: session.sessionType == 'daily_weight' ? 'Weight' : 'Pre-Dialysis',
                            value: '$preWeight kg',
                          ),
                        if (postWeight != null)
                          _Metric(
                            label: 'Post-Dialysis',
                            value: '$postWeight kg',
                          ),
                        if (dryWeight != null)
                          _Metric(
                            label: 'Prescribed Dry',
                            value: '$dryWeight kg',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Fluid metrics / variance
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (idwg != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Gain (IDWG): ${idwg >= 0 ? "+" : ""}${idwg.toStringAsFixed(2)} kg',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        if (varianceFromDryWeight != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: varianceFromDryWeight > 0.5
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Variance: ${varianceFromDryWeight >= 0 ? "+" : ""}${varianceFromDryWeight.toStringAsFixed(2)} kg',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: varianceFromDryWeight > 0.5 ? Colors.orange.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        if (ufRemoved != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Fluid Removed: $ufRemoved mL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (session.notes != null && session.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Notes: ${session.notes}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => Text('Error loading weight trends: $e'),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
