import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../dialysis/data/dialysis_session_repository.dart';
import '../../profile/domain/clinical_condition.dart';

/// Screen allowing CKD and Urological/Catheter patients to log symptoms
/// (such as fatigue, edema, catheter spasms, fever, or pain) and view a
/// longitudinal symptom surveillance timeline per CONTEXT.md and User Story 18.
class SymptomLogScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const SymptomLogScreen({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends ConsumerState<SymptomLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final Set<String> _selectedSymptoms = <String>{};
  bool _isSubmitting = false;

  late final ClinicalCondition _condition;

  static const List<String> _ckdSymptoms = [
    'Fatigue / Exhaustion',
    'Edema (Leg/Ankle Swelling)',
    'Shortness of Breath',
    'Loss of Appetite',
    'Nausea / Uremic Taste',
    'Muscle Cramping',
    'Itching / Pruritus',
    'Foamy Urine',
    'Dizziness',
  ];

  static const List<String> _uroSymptoms = [
    'Catheter Pain / Discomfort',
    'Bladder Spasms',
    'Cloudy / Foul Urine',
    'Catheter Leakage (Bypass)',
    'Blockage / Decreased Output',
    'Fever / Chills',
    'Hematuria / Bleeding',
    'Flank / Lower Back Pain',
  ];

  @override
  void initState() {
    super.initState();
    _condition = ClinicalCondition.fromString(widget.patient.diagnosis) ?? ClinicalCondition.nonDialysisCkd;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _symptomOptions {
    if (_condition == ClinicalCondition.urologicalCatheter) {
      return _uroSymptoms;
    }
    return _ckdSymptoms;
  }

  bool get _hasCriticalSymptoms {
    return _selectedSymptoms.any((s) =>
        s.contains('Fever') ||
        s.contains('Cloudy') ||
        s.contains('Shortness of Breath') ||
        s.contains('Blockage'));
  }

  Future<void> _submitSymptoms() async {
    if (_selectedSymptoms.isEmpty && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom or enter a clinical note.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(dialysisSessionRepositoryProvider);
      final sessionType = _condition == ClinicalCondition.urologicalCatheter ? 'uro_symptom' : 'ckd_symptom';

      await repo.recordSymptomLog(
        patientId: widget.patient.id,
        symptoms: _selectedSymptoms.toList(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        sessionType: sessionType,
        recordedAt: DateTime.now().toUtc(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptoms recorded successfully!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _selectedSymptoms.clear();
          _notesController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record symptoms: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
    final sessionsAsync = ref.watch(dialysisSessionsStreamProvider(widget.patient.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(_condition == ClinicalCondition.urologicalCatheter
            ? 'Urological Symptom Log'
            : 'CKD Symptom Log'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Overview Card
            _buildHeaderCard(theme),
            const SizedBox(height: 16),

            // 2. Symptom Logging Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.healing_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Record Today\'s Symptoms',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select all symptoms experienced today:',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                      ),
                      const Divider(height: 20),

                      // Multi-Select Symptom Filter Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _symptomOptions.map((symptom) {
                          final isSelected = _selectedSymptoms.contains(symptom);
                          return FilterChip(
                            key: Key('symptom_chip_${symptom.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}'),
                            label: Text(symptom),
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor: theme.colorScheme.primary,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSymptoms.add(symptom);
                                } else {
                                  _selectedSymptoms.remove(symptom);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      // Critical Symptoms Advisory Alert
                      if (_hasCriticalSymptoms) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.colorScheme.error),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Red Flag Symptom: Severe shortness of breath, fever, or acute catheter obstruction requires immediate clinical consultation.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Additional Notes
                      TextFormField(
                        key: const Key('symptom_notes_field'),
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Clinical Notes / Severity (Optional)',
                          hintText: 'e.g., mild swelling starting after 5pm, relieved by elevation',
                          prefixIcon: Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton.icon(
                        key: const Key('save_symptom_log_button'),
                        onPressed: _isSubmitting ? null : _submitSymptoms,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('Save Symptom Entry'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Longitudinal Symptom Timeline Section
            Text(
              'Symptom Surveillance Timeline',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            sessionsAsync.when(
              data: (sessions) {
                final symptomSessions = sessions.where((s) =>
                    (s.symptoms != null && s.symptoms!.isNotEmpty) ||
                    s.sessionType.contains('symptom')).toList();

                if (symptomSessions.isEmpty) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No symptoms logged yet.\nRecord symptoms above to track clinical patterns over time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: symptomSessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final session = symptomSessions[index];
                    return _buildSymptomTimelineCard(context, theme, session);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading symptoms: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.healing_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patient.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    _condition == ClinicalCondition.urologicalCatheter
                        ? 'Catheter Spasms, Pain & Infection Monitoring'
                        : 'Conservative CKD Symptom Surveillance',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomTimelineCard(BuildContext context, ThemeData theme, DialysisSession session) {
    final timeStr = _formatTimestamp(session.startedAt);
    final symptomsStr = session.symptoms ?? '';
    final notes = session.notes ?? '';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_note_rounded, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Symptom Entry?'),
                          content: const Text('Are you sure you want to remove this symptom log entry?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        final repo = ref.read(dialysisSessionRepositoryProvider);
                        await repo.deleteDialysisSession(session.id);
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete Entry', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (symptomsStr.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: symptomsStr.split(', ').map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: $notes',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
