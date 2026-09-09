import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../profile/domain/clinical_condition.dart';
import '../data/dialysis_session_repository.dart';
import '../domain/hemodialysis_calculation_rules.dart';

/// Screen presenting the longitudinal timeline of all past exit-site and fistula inspection notes,
/// alongside a checklist form to record new exit-site and vascular access evaluations.
class AccessInspectionHistoryScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const AccessInspectionHistoryScreen({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<AccessInspectionHistoryScreen> createState() => _AccessInspectionHistoryScreenState();
}

class _AccessInspectionHistoryScreenState extends ConsumerState<AccessInspectionHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  bool _thrillPresent = false;
  bool _bruitPresent = false;
  bool _rednessPresent = false;
  bool _swellingPresent = false;
  bool _dischargePresent = false;
  bool _painPresent = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _accessWarnings {
    final accessType = widget.patient.vascularAccessType ?? '';
    return HemodialysisCalculationRules.getAccessSafetyWarnings(
      accessType: accessType,
      thrillPresent: _thrillPresent,
      bruitPresent: _bruitPresent,
      rednessPresent: _rednessPresent,
      swellingPresent: _swellingPresent,
      dischargePresent: _dischargePresent,
      painPresent: _painPresent,
    );
  }

  Future<void> _submitInspection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(dialysisSessionRepositoryProvider);
      await repo.recordAccessInspection(
        patientId: widget.patient.id,
        accessType: widget.patient.vascularAccessType,
        anatomicalLocation: widget.patient.fistulaArmLocation,
        thrillPresent: _thrillPresent,
        bruitPresent: _bruitPresent,
        rednessPresent: _rednessPresent,
        swellingPresent: _swellingPresent,
        dischargePresent: _dischargePresent,
        painPresent: _painPresent,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        recordedAt: DateTime.now().toUtc(),
      );

      if (mounted) {
        _notesController.clear();
        setState(() {
          _thrillPresent = false;
          _bruitPresent = false;
          _rednessPresent = false;
          _swellingPresent = false;
          _dischargePresent = false;
          _painPresent = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access inspection recorded successfully.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record inspection: $e'),
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
    final accessType = widget.patient.vascularAccessType ?? '';
    final accessLocation = AccessLocation.fromString(widget.patient.fistulaArmLocation);

    final isFistulaOrGraft = accessType == VascularAccessType.arteriovenousFistula.name ||
        accessType == VascularAccessType.arteriovenousGraft.name;
    final isCentralLine = accessType == VascularAccessType.dialysisCentralLine.name;
    final isPdAccess = accessType == VascularAccessType.peritonealDialysisAccess.name;
    final warnings = _accessWarnings;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vascular & Exit-Site Inspection',
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
              // 1. Access Overview Header Card
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
                          Icon(Icons.health_and_safety_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Designated Access Information',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Access Modality:'),
                          Chip(
                            label: Text(
                              isFistulaOrGraft
                                  ? 'Arteriovenous Fistula / Graft'
                                  : isCentralLine
                                      ? 'Dialysis Central Line (Permcath)'
                                      : isPdAccess
                                          ? 'Peritoneal Dialysis Access'
                                          : 'None / General',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Anatomical Location:'),
                          Text(
                            accessLocation?.displayName ?? 'Not specified',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. New Inspection Entry Form
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
                          'Record Access Inspection',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Checkbox indicators
                        if (isFistulaOrGraft) ...[
                          CheckboxListTile(
                            key: const Key('inspection_thrill_checkbox'),
                            title: const Text('Thrill Present (Palpable Vibration)'),
                            subtitle: const Text('Confirms continuous blood flow patency'),
                            value: _thrillPresent,
                            onChanged: (val) => setState(() => _thrillPresent = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            key: const Key('inspection_bruit_checkbox'),
                            title: const Text('Bruit Present (Audible Whoosh)'),
                            subtitle: const Text('Confirms audible bruit with stethoscope'),
                            value: _bruitPresent,
                            onChanged: (val) => setState(() => _bruitPresent = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ] else ...[
                          CheckboxListTile(
                            key: const Key('inspection_redness_checkbox'),
                            title: const Text('Exit-Site Redness (Erythema)'),
                            subtitle: const Text('Skin redness surrounding catheter exit site'),
                            value: _rednessPresent,
                            onChanged: (val) => setState(() => _rednessPresent = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            key: const Key('inspection_swelling_checkbox'),
                            title: const Text('Exit-Site Swelling (Edema)'),
                            subtitle: const Text('Tissue puffiness or induration'),
                            value: _swellingPresent,
                            onChanged: (val) => setState(() => _swellingPresent = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            key: const Key('inspection_discharge_checkbox'),
                            title: const Text('Exit-Site Discharge / Exudate'),
                            subtitle: const Text('Pus, purulent drainage, or bleeding'),
                            value: _dischargePresent,
                            onChanged: (val) => setState(() => _dischargePresent = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            key: const Key('inspection_pain_checkbox'),
                            title: const Text('Exit-Site Pain or Tenderness'),
                            subtitle: const Text('Discomfort on gentle palpation'),
                            value: _painPresent,
                            onChanged: (val) => setState(() => _painPresent = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],

                        // Warning banner if safety warnings exist
                        if (warnings.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            key: const Key('inspection_warning_banner'),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.error),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Clinical Infection / Thrombosis Alert',
                                      style: TextStyle(
                                        color: theme.colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ...warnings.map((w) => Text('• $w', style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12))),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('inspection_notes_input'),
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Clinical Notes (Optional)',
                            hintText: 'e.g. Cleansed with chlorhexidine, dressing changed',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            key: const Key('save_inspection_button'),
                            onPressed: _isSubmitting ? null : _submitInspection,
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: Text(_isSubmitting ? 'Saving...' : 'Save Inspection Log'),
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

              // 3. Longitudinal Inspection Timeline Section (US 35)
              Text(
                'Longitudinal Inspection Timeline',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _LongitudinalInspectionTimeline(patient: widget.patient),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reactive list of past access inspections ordered most recent first.
class _LongitudinalInspectionTimeline extends ConsumerWidget {
  final Patient patient;

  const _LongitudinalInspectionTimeline({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionsAsync = ref.watch(accessInspectionsStreamProvider(patient.id));
    final theme = Theme.of(context);

    return inspectionsAsync.when(
      data: (inspections) {
        if (inspections.isEmpty) {
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No vascular access inspections logged yet.')),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: inspections.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = inspections[index];
            final formattedDate =
                '${item.recordedAt.year}-${item.recordedAt.month.toString().padLeft(2, '0')}-${item.recordedAt.day.toString().padLeft(2, '0')} ${item.recordedAt.hour.toString().padLeft(2, '0')}:${item.recordedAt.minute.toString().padLeft(2, '0')}';

            final hasSigns = (item.rednessPresent == true) ||
                (item.swellingPresent == true) ||
                (item.dischargePresent == true) ||
                (item.painPresent == true);

            final isThrillMissing = item.thrillPresent == false &&
                (item.accessType == VascularAccessType.arteriovenousFistula.name ||
                    item.accessType == VascularAccessType.arteriovenousGraft.name);

            final hasAbnormality = hasSigns || isThrillMissing;

            return Card(
              key: Key('inspection_tile_${item.id}'),
              elevation: 0,
              color: hasAbnormality ? theme.colorScheme.errorContainer.withValues(alpha: 0.3) : theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: hasAbnormality ? theme.colorScheme.error : theme.colorScheme.outlineVariant,
                  width: hasAbnormality ? 1.5 : 1.0,
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
                            Icon(
                              hasAbnormality ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                              color: hasAbnormality ? theme.colorScheme.error : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(
                            hasAbnormality ? 'Attention Required' : 'Nominal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: hasAbnormality ? theme.colorScheme.error : Colors.green.shade800,
                            ),
                          ),
                          backgroundColor: hasAbnormality
                              ? theme.colorScheme.errorContainer
                              : Colors.green.withValues(alpha: 0.15),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Finding Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.thrillPresent == true)
                          _badge('Thrill +', Colors.green)
                        else if (item.thrillPresent == false)
                          _badge('Thrill Missing', Colors.red),

                        if (item.bruitPresent == true)
                          _badge('Bruit +', Colors.green)
                        else if (item.bruitPresent == false)
                          _badge('Bruit Missing', Colors.red),

                        if (item.rednessPresent == true) _badge('Redness', Colors.orange.shade800),
                        if (item.swellingPresent == true) _badge('Swelling', Colors.orange.shade800),
                        if (item.dischargePresent == true) _badge('Discharge', Colors.red),
                        if (item.painPresent == true) _badge('Pain', Colors.orange.shade800),
                        if (!hasSigns && (item.thrillPresent ?? false))
                          _badge('Clean / No Signs', Colors.green),
                      ],
                    ),

                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Notes: ${item.notes}',
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
      error: (e, _) => Text('Error loading inspection timeline: $e'),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
