import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/dialysis_session_repository.dart';
import '../domain/hemodialysis_calculation_rules.dart';

/// Post-dialysis session logging screen.
///
/// Captures post-dialysis weight, computes difference from Prescribed Dry Weight,
/// and records actual fluid removed along with post-treatment recovery symptoms
/// (muscle cramping, dizziness, hypotension, nausea, fatigue).
class HemodialysisPostSessionScreen extends ConsumerStatefulWidget {
  final Patient patient;
  final DialysisSession? existingSession;

  const HemodialysisPostSessionScreen({
    super.key,
    required this.patient,
    this.existingSession,
  });

  @override
  ConsumerState<HemodialysisPostSessionScreen> createState() => _HemodialysisPostSessionScreenState();
}

class _HemodialysisPostSessionScreenState extends ConsumerState<HemodialysisPostSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postWeightController = TextEditingController();
  final _fluidRemovedController = TextEditingController();
  final _notesController = TextEditingController();

  final Set<String> _selectedSymptoms = {};
  bool _hasInitialized = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _postWeightController.addListener(_onWeightChanged);
    if (widget.existingSession != null) {
      _initFromSession(widget.existingSession!);
      _hasInitialized = true;
    }
  }

  void _onWeightChanged() {
    setState(() {});
  }

  void _initFromSession(DialysisSession session) {
    if (session.postWeightKg != null && _postWeightController.text.isEmpty) {
      _postWeightController.text = session.postWeightKg.toString();
    }
    if (session.actualFluidRemovedMl != null && _fluidRemovedController.text.isEmpty) {
      _fluidRemovedController.text = session.actualFluidRemovedMl.toString();
    }
    if (session.notes != null && _notesController.text.isEmpty) {
      _notesController.text = session.notes!;
    }
    if (session.symptoms != null && session.symptoms!.isNotEmpty && _selectedSymptoms.isEmpty) {
      final symptomList = session.symptoms!.split(',').map((s) => s.trim().toLowerCase());
      _selectedSymptoms.addAll(symptomList);
    }
  }

  @override
  void dispose() {
    _postWeightController.removeListener(_onWeightChanged);
    _postWeightController.dispose();
    _fluidRemovedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _currentPostWeight => double.tryParse(_postWeightController.text.trim());
  int? get _actualFluidRemoved => int.tryParse(_fluidRemovedController.text.trim());

  double? get _postWeightDifference {
    final postWeight = _currentPostWeight;
    final dryWeight = widget.patient.prescribedDryWeightKg;
    if (postWeight == null || dryWeight == null) return null;
    return HemodialysisCalculationRules.calculatePostWeightDifference(
      postWeightKg: postWeight,
      prescribedDryWeightKg: dryWeight,
    );
  }

  Future<void> _savePostSession(DialysisSession? activeSession) async {
    if (!_formKey.currentState!.validate()) return;
    final postWeight = _currentPostWeight;
    if (postWeight == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(dialysisSessionRepositoryProvider);

      String targetSessionId;
      if (activeSession != null) {
        targetSessionId = activeSession.id;
      } else {
        // Create an active session if none exists
        final newSession = await repo.recordPreDialysisCheckIn(
          patientId: widget.patient.id,
          preWeightKg: postWeight,
          startedAt: DateTime.now().subtract(const Duration(hours: 4)),
        );
        targetSessionId = newSession.id;
      }

      await repo.recordPostDialysisSession(
        sessionId: targetSessionId,
        postWeightKg: postWeight,
        actualFluidRemovedMl: _actualFluidRemoved,
        symptoms: _selectedSymptoms.toList(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post-dialysis session logged successfully.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save post-dialysis log: $e'),
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
    final diff = _postWeightDifference;

    final sessionsAsync = ref.watch(dialysisSessionsStreamProvider(widget.patient.id));
    final sessionFromStream = sessionsAsync.valueOrNull?.where((s) => s.endedAt == null).firstOrNull ??
        sessionsAsync.valueOrNull?.firstOrNull;
    final activeSession = widget.existingSession ?? sessionFromStream;

    if (!_hasInitialized && activeSession != null) {
      _initFromSession(activeSession);
      _hasInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post-Dialysis Session Log'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Session Context Card
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
                            Icon(Icons.assignment_turned_in_rounded, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Session Overview',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Prescribed Dry Weight:', style: theme.textTheme.bodyMedium),
                            Text(
                              dryWeight != null ? '$dryWeight kg' : 'Not set',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (activeSession?.preWeightKg != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pre-Dialysis Weight:', style: theme.textTheme.bodyMedium),
                              Text(
                                '${activeSession!.preWeightKg} kg',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                        if (activeSession?.calculatedUltrafiltrationGoalMl != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ultrafiltration Goal:', style: theme.textTheme.bodyMedium),
                              Text(
                                '${activeSession!.calculatedUltrafiltrationGoalMl} mL',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                      const SizedBox(height: 16),

                      // 2. Post-Dialysis Measurements
                      Text(
                        'Post-Treatment Measurements',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('post_weight_input'),
                        controller: _postWeightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Post-Dialysis Weight (kg) *',
                          hintText: 'e.g. 70.2',
                          prefixIcon: Icon(Icons.scale_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter post-dialysis weight';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0 || parsed > 300) {
                            return 'Enter a valid body weight between 1 and 300 kg';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('fluid_removed_input'),
                        controller: _fluidRemovedController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Actual Fluid Removed (mL)',
                          hintText: 'e.g. 2500',
                          prefixIcon: Icon(Icons.opacity_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Difference from Prescribed Dry Weight
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Variance from Prescribed Dry Weight',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    diff == null
                                        ? Icons.help_outline_rounded
                                        : diff == 0
                                            ? Icons.check_circle_outline_rounded
                                            : diff > 0
                                                ? Icons.arrow_upward_rounded
                                                : Icons.arrow_downward_rounded,
                                    color: diff == null
                                        ? theme.colorScheme.onSurfaceVariant
                                        : diff == 0
                                            ? Colors.green
                                            : diff > 0
                                                ? Colors.orange
                                                : Colors.blue,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          diff != null
                                              ? '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(2)} kg'
                                              : '-- kg',
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          diff == null
                                              ? 'Enter post-weight to compute variance'
                                              : diff == 0
                                                  ? 'Reached exact Prescribed Dry Weight'
                                                  : diff > 0
                                                      ? 'Above dry weight (residual fluid excess)'
                                                      : 'Below dry weight (potential over-dialysis/dehydration)',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Post-Treatment Symptoms
                      Text(
                        'Post-Treatment Symptoms',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select any symptoms experienced during or following treatment:',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSymptomFilterChip(
                            key: const Key('symptom_cramping_chip'),
                            label: 'Muscle Cramping',
                            value: 'cramping',
                          ),
                          _buildSymptomFilterChip(
                            key: const Key('symptom_dizziness_chip'),
                            label: 'Dizziness',
                            value: 'dizziness',
                          ),
                          _buildSymptomFilterChip(
                            key: const Key('symptom_hypotension_chip'),
                            label: 'Hypotension (Low BP)',
                            value: 'hypotension',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes Input
                      TextFormField(
                        key: const Key('post_notes_input'),
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Session Notes (Optional)',
                          hintText: 'e.g. Early termination, saline flushes, recovery notes',
                          prefixIcon: Icon(Icons.note_alt_rounded),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      // 5. Submit Button (Touch target min 48dp)
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          key: const Key('save_post_session_button'),
                          onPressed: _isSubmitting ? null : () => _savePostSession(activeSession),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _isSubmitting ? 'Saving Session Log...' : 'Save Post-Dialysis Log',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSymptomFilterChip({
    required Key key,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedSymptoms.contains(value);
    return FilterChip(
      key: key,
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedSymptoms.add(value);
          } else {
            _selectedSymptoms.remove(value);
          }
        });
      },
    );
  }
}
