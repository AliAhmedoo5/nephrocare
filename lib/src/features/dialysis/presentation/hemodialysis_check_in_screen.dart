import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../profile/domain/clinical_condition.dart';
import '../data/dialysis_session_repository.dart';
import '../domain/hemodialysis_calculation_rules.dart';
import 'access_inspection_history_screen.dart';
import 'weight_trends_screen.dart';

/// Hemodialysis pre-session check-in screen.
///
/// Captures pre-dialysis weight, automatically computes Interdialytic Weight Gain (IDWG)
/// against the previous session and Ultrafiltration (UF) Goal against Prescribed Dry Weight,
/// and conducts pre-session access safety inspection.
class HemodialysisCheckInScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const HemodialysisCheckInScreen({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<HemodialysisCheckInScreen> createState() => _HemodialysisCheckInScreenState();
}

class _HemodialysisCheckInScreenState extends ConsumerState<HemodialysisCheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _preWeightController = TextEditingController();
  final _volumeAllowanceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  // Access inspection states
  bool _thrillPresent = false;
  bool _bruitPresent = false;
  bool _rednessPresent = false;
  bool _swellingPresent = false;
  bool _dischargePresent = false;
  bool _painPresent = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _preWeightController.addListener(_onCalculationsChanged);
    _volumeAllowanceController.addListener(_onCalculationsChanged);
  }

  void _onCalculationsChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _preWeightController.removeListener(_onCalculationsChanged);
    _volumeAllowanceController.removeListener(_onCalculationsChanged);
    _preWeightController.dispose();
    _volumeAllowanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _currentPreWeight => double.tryParse(_preWeightController.text.trim());
  int get _volumeAllowance => int.tryParse(_volumeAllowanceController.text.trim()) ?? 0;

  double? _calculateIdwg(double? previousPostWeight) {
    final preWeight = _currentPreWeight;
    if (preWeight == null) return null;
    return HemodialysisCalculationRules.calculateInterdialyticWeightGain(
      currentPreWeightKg: preWeight,
      previousPostWeightKg: previousPostWeight,
      prescribedDryWeightKg: widget.patient.prescribedDryWeightKg,
    );
  }

  int? get _calculatedUfGoal {
    final preWeight = _currentPreWeight;
    final dryWeight = widget.patient.prescribedDryWeightKg;
    if (preWeight == null || dryWeight == null) return null;
    return HemodialysisCalculationRules.calculateUltrafiltrationGoal(
      currentPreWeightKg: preWeight,
      prescribedDryWeightKg: dryWeight,
      volumeAllowanceMl: _volumeAllowance,
    );
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

  Future<void> _submitCheckIn() async {
    if (!_formKey.currentState!.validate()) return;
    final preWeight = _currentPreWeight;
    if (preWeight == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(dialysisSessionRepositoryProvider);
      await repo.recordPreDialysisCheckIn(
        patientId: widget.patient.id,
        preWeightKg: preWeight,
        volumeAllowanceMl: _volumeAllowance,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        thrillPresent: _thrillPresent,
        bruitPresent: _bruitPresent,
        rednessPresent: _rednessPresent,
        swellingPresent: _swellingPresent,
        dischargePresent: _dischargePresent,
        painPresent: _painPresent,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hemodialysis check-in recorded successfully.'),
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
            content: Text('Failed to record check-in: $e'),
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
    final sessionsAsync = ref.watch(dialysisSessionsStreamProvider(widget.patient.id));
    final previousSession = sessionsAsync.valueOrNull?.where((s) => s.postWeightKg != null).firstOrNull;
    final previousPostWeight = previousSession?.postWeightKg;
    final calculatedIdwg = _calculateIdwg(previousPostWeight);

    final accessType = widget.patient.vascularAccessType ?? '';
    final isFistulaOrGraft = accessType == VascularAccessType.arteriovenousFistula.name ||
        accessType == VascularAccessType.arteriovenousGraft.name;
    final isCentralLine = accessType == VascularAccessType.dialysisCentralLine.name;
    final warnings = _accessWarnings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hemodialysis Check-In'),
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
                // 1. Patient Prescribed Target Card
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.monitor_weight_rounded, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Prescribed Clinical Targets',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              key: const Key('view_weight_trends_button'),
                              icon: const Icon(Icons.show_chart_rounded, size: 18),
                              label: const Text('Trends'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => WeightTrendsScreen(patient: widget.patient),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Prescribed Dry Weight:',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              widget.patient.prescribedDryWeightKg != null
                                  ? '${widget.patient.prescribedDryWeightKg} kg'
                                  : 'Not set',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Previous Post-Dialysis Weight:',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              previousPostWeight != null
                                  ? '$previousPostWeight kg'
                                  : (widget.patient.prescribedDryWeightKg != null
                                      ? '${widget.patient.prescribedDryWeightKg} kg (Dry Weight)'
                                      : 'None'),
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Weight & Allowance Inputs
                Text(
                  'Pre-Dialysis Measurements',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('pre_weight_input'),
                  controller: _preWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Pre-Dialysis Weight (kg) *',
                    hintText: 'e.g. 72.5',
                    prefixIcon: Icon(Icons.scale_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter pre-dialysis weight';
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
                  key: const Key('volume_allowance_input'),
                  controller: _volumeAllowanceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Volume Allowance (mL)',
                    hintText: 'e.g. 300 (Rinseback / Oral fluid during treatment)',
                    prefixIcon: Icon(Icons.water_drop_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Automated Calculations Card
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
                          'Automated Interdialytic Calculations',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Interdialytic Weight Gain',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    calculatedIdwg != null
                                        ? '${calculatedIdwg >= 0 ? "+" : ""}${calculatedIdwg.toStringAsFixed(2)} kg'
                                        : '--',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ultrafiltration Goal',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _calculatedUfGoal != null ? '$_calculatedUfGoal mL' : '--',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
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

                // 4. Pre-Session Vascular Access Inspection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pre-Session Vascular Access Inspection',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      key: const Key('view_access_history_button'),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('History'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AccessInspectionHistoryScreen(patient: widget.patient),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isFistulaOrGraft
                      ? 'Inspect your arteriovenous fistula/graft. Confirm thrill (vibration) and bruit (sound).'
                      : isCentralLine
                          ? 'Inspect dialysis central catheter exit site for signs of infection.'
                          : 'General vascular access inspection.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),

                // Inspection Checkboxes
                if (isFistulaOrGraft) ...[
                  CheckboxListTile(
                    key: const Key('thrill_checkbox'),
                    title: const Text('Thrill Present (palpable continuous vibration)'),
                    value: _thrillPresent,
                    onChanged: (val) => setState(() => _thrillPresent = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  CheckboxListTile(
                    key: const Key('bruit_checkbox'),
                    title: const Text('Bruit Present (audible machine-like whoosh)'),
                    value: _bruitPresent,
                    onChanged: (val) => setState(() => _bruitPresent = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ] else if (isCentralLine) ...[
                  CheckboxListTile(
                    key: const Key('redness_checkbox'),
                    title: const Text('Exit-Site Redness'),
                    subtitle: const Text('Red erythema around skin catheter exit site'),
                    value: _rednessPresent,
                    onChanged: (val) => setState(() => _rednessPresent = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  CheckboxListTile(
                    key: const Key('swelling_checkbox'),
                    title: const Text('Exit-Site Swelling'),
                    subtitle: const Text('Edema or puffy tissue around insertion site'),
                    value: _swellingPresent,
                    onChanged: (val) => setState(() => _swellingPresent = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  CheckboxListTile(
                    key: const Key('discharge_checkbox'),
                    title: const Text('Exit-Site Discharge'),
                    subtitle: const Text('Pus, exudate, or fluid leaking from cuff'),
                    value: _dischargePresent,
                    onChanged: (val) => setState(() => _dischargePresent = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  CheckboxListTile(
                    key: const Key('pain_checkbox'),
                    title: const Text('Exit-Site Pain or Tenderness'),
                    value: _painPresent,
                    onChanged: (val) => setState(() => _painPresent = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ],

                // Access Warning Banner if warnings present
                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('access_safety_warning_banner'),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.error),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Access Safety Alert',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...warnings.map(
                                (w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Text(
                                    '• $w',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Notes Field
                TextFormField(
                  key: const Key('check_in_notes_input'),
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Notes (Optional)',
                    hintText: 'e.g. Needle gauge, heparin, or access notes',
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
                    key: const Key('confirm_check_in_button'),
                    onPressed: _isSubmitting ? null : _submitCheckIn,
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
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _isSubmitting ? 'Recording Check-In...' : 'Confirm Check-In',
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
}
