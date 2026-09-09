import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../profile/data/patient_repository.dart';
import '../../profile/domain/clinical_condition.dart';
import '../data/blood_pressure_repository.dart';
import '../domain/vascular_safety_rules.dart';
import 'paired_bp_dialogs.dart';

/// Blood pressure entry screen enforcing the Fistula Arm Safety Flag
/// and hard lockout per ADR-0003, with reactive hemodynamic trend visualization.
class BloodPressureEntryScreen extends ConsumerStatefulWidget {
  final Patient? patient;

  const BloodPressureEntryScreen({
    super.key,
    this.patient,
  });

  @override
  ConsumerState<BloodPressureEntryScreen> createState() => _BloodPressureEntryScreenState();
}

class _BloodPressureEntryScreenState extends ConsumerState<BloodPressureEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();

  String _selectedArm = 'leftArm';
  String? _lastPatientId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _applyPatient(widget.patient!);
    }
  }

  @override
  void didUpdateWidget(covariant BloodPressureEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patient != null && widget.patient!.id != _lastPatientId) {
      _applyPatient(widget.patient!);
    }
  }

  void _applyPatient(Patient patient) {
    _lastPatientId = patient.id;
    _selectedArm = patient.safeArm ?? 'leftArm';
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _submitReading(Patient patient) async {
    if (!_formKey.currentState!.validate()) return;

    // Safety guardrail check
    if (!patient.isArmSafe(_selectedArm)) {
      final armDisplayName = AccessLocation.fromString(_selectedArm)?.displayName ?? _selectedArm;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Safety Violation: $armDisplayName has an active fistula/graft. Hard lockout enforced.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final systolic = int.parse(_systolicController.text.trim());
      final diastolic = int.parse(_diastolicController.text.trim());
      final pulse = int.parse(_pulseController.text.trim());

      await ref.read(bloodPressureRepositoryProvider).recordBloodPressure(
            patientId: patient.id,
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            armUsed: _selectedArm,
            recordedAt: DateTime.now().toUtc(),
          );

      if (mounted) {
        _systolicController.clear();
        _diastolicController.clear();
        _pulseController.clear();

        final armDisplayName = AccessLocation.fromString(_selectedArm)?.displayName ?? _selectedArm;
        final safeSuffix = patient.hasArmAccess ? ' (Safe Arm)' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Blood pressure logged: $systolic/$diastolic mmHg on $armDisplayName$safeSuffix.',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording blood pressure: $e'),
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

    // Reactively observe patient updates when not explicitly fixed via widget
    if (widget.patient == null) {
      ref.listen<AsyncValue<Patient?>>(activePatientStreamProvider, (previous, next) {
        final active = next.valueOrNull;
        if (active != null && active.id != _lastPatientId) {
          setState(() {
            _applyPatient(active);
          });
        }
      });
    }

    final activePatientAsync = ref.watch(activePatientStreamProvider);
    final Patient? patient = widget.patient ?? activePatientAsync.valueOrNull;

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Blood Pressure')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pendingFollowUpsAsync = ref.watch(pendingFollowUpAssessmentsStreamProvider(patient.id));
    final pendingFollowUps = pendingFollowUpsAsync.valueOrNull ?? const [];

    if (_lastPatientId == null) {
      _applyPatient(patient);
    }

    final hasArmAccess = patient.hasArmAccess;
    final prohibitedArm = patient.prohibitedArm;
    final accessLocation = AccessLocation.fromString(patient.fistulaArmLocation);

    final isLeftProhibited = prohibitedArm == 'leftArm';
    final isRightProhibited = prohibitedArm == 'rightArm';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Blood Pressure Log',
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
              // Pending Paired Assessment Follow-Up Banner
              if (pendingFollowUps.isNotEmpty) ...[
                Container(
                  key: const Key('pending_followup_banner'),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.tertiary,
                      width: 2.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.alarm_on_rounded,
                            color: theme.colorScheme.onTertiaryContainer,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Follow-Up BP Measurement Due',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Baseline: ${pendingFollowUps.first.systolic}/${pendingFollowUps.first.diastolic} mmHg (${pendingFollowUps.first.pulse} bpm) on ${AccessLocation.fromString(pendingFollowUps.first.armUsed)?.displayName ?? pendingFollowUps.first.armUsed}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          key: const Key('entry_log_paired_followup_button'),
                          icon: const Icon(Icons.favorite_rounded, size: 18),
                          label: const Text('Log Follow-Up Measurement', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.tertiary,
                            foregroundColor: theme.colorScheme.onTertiary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            showFollowUpBpPromptDialog(
                              context: context,
                              ref: ref,
                              patient: patient,
                              baseline: pendingFollowUps.first,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Fistula Arm Safety Flag Banner per ADR-0003
              if (hasArmAccess) ...[
                Container(
                  key: const Key('fistula_arm_safety_banner'),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.error,
                      width: 2.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.gpp_bad_rounded,
                        color: theme.colorScheme.onErrorContainer,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fistula Arm Safety Flag Active',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${accessLocation?.displayName ?? 'Designated arm'} bears an active vascular access. Blood pressure cuff inflation, IV lines, and venipuncture are strictly prohibited on this arm to prevent vascular thrombosis and access failure. Hard lockout is enforced below.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Arm Selection Section with Hard Lockout
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.accessibility_new_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Measurement Arm Selection',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ArmSelectionButton(
                              buttonKey: const Key('arm_left_button'),
                              label: 'Left Arm',
                              isProhibited: isLeftProhibited,
                              isSelected: _selectedArm == 'leftArm',
                              onPressed: isLeftProhibited
                                  ? null
                                  : () => setState(() => _selectedArm = 'leftArm'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ArmSelectionButton(
                              buttonKey: const Key('arm_right_button'),
                              label: 'Right Arm',
                              isProhibited: isRightProhibited,
                              isSelected: _selectedArm == 'rightArm',
                              onPressed: isRightProhibited
                                  ? null
                                  : () => setState(() => _selectedArm = 'rightArm'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Blood Pressure Input Form
              Form(
                key: _formKey,
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Blood Pressure Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Systolic Field
                        TextFormField(
                          key: const Key('systolic_input'),
                          controller: _systolicController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Systolic Blood Pressure (mmHg) *',
                            hintText: 'e.g., 120',
                            prefixIcon: const Icon(Icons.favorite_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter systolic pressure';
                            }
                            final val = int.tryParse(value.trim());
                            if (val == null || val < 50 || val > 300) {
                              return 'Enter a valid systolic reading (50 - 300 mmHg)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Diastolic Field
                        TextFormField(
                          key: const Key('diastolic_input'),
                          controller: _diastolicController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Diastolic Blood Pressure (mmHg) *',
                            hintText: 'e.g., 80',
                            prefixIcon: const Icon(Icons.favorite_border_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter diastolic pressure';
                            }
                            final val = int.tryParse(value.trim());
                            if (val == null || val < 30 || val > 200) {
                              return 'Enter a valid diastolic reading (30 - 200 mmHg)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Pulse Field
                        TextFormField(
                          key: const Key('pulse_input'),
                          controller: _pulseController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Heart Rate / Pulse (bpm) *',
                            hintText: 'e.g., 72',
                            prefixIcon: const Icon(Icons.monitor_heart_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter pulse rate';
                            }
                            final val = int.tryParse(value.trim());
                            if (val == null || val < 30 || val > 220) {
                              return 'Enter a valid pulse reading (30 - 220 bpm)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Submit Button (Min 48dp height)
                        SizedBox(
                          height: 52.0,
                          child: ElevatedButton(
                            key: const Key('save_bp_button'),
                            onPressed: _isSubmitting ? null : () => _submitReading(patient),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator.adaptive()
                                : const Text(
                                    'Save Blood Pressure Log',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Historical Hemodynamic Trends Section
              Text(
                'Historical Blood Pressure Trends',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _HemodynamicTrendsList(patient: patient),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable arm selection button with high-contrast accessibility and lockout styling.
class _ArmSelectionButton extends StatelessWidget {
  final Key buttonKey;
  final String label;
  final bool isProhibited;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _ArmSelectionButton({
    required this.buttonKey,
    required this.label,
    required this.isProhibited,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String displayLabel = isProhibited ? '$label (Locked)' : label;

    return SizedBox(
      height: 52.0,
      child: ElevatedButton.icon(
        key: buttonKey,
        icon: Icon(
          isProhibited ? Icons.lock_outline_rounded : Icons.check_circle_outline_rounded,
        ),
        label: Text(
          displayLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isProhibited
              ? theme.colorScheme.surfaceContainerLow
              : isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
          foregroundColor: isProhibited
              ? theme.colorScheme.outline
              : isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
          side: BorderSide(
            color: isProhibited
                ? theme.colorScheme.error.withValues(alpha: 0.5)
                : isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

/// Reactive widget observing and rendering hemodynamic logs for a patient.
class _HemodynamicTrendsList extends ConsumerWidget {
  final Patient patient;

  const _HemodynamicTrendsList({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(bloodPressureLogsStreamProvider(patient.id));
    final theme = Theme.of(context);

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('No blood pressure records yet.'),
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: logs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = logs[index];
            final armName = AccessLocation.fromString(log.armUsed)?.displayName ?? log.armUsed;
            final isSafeArmIndicated = patient.hasArmAccess;
            final chipLabel = isSafeArmIndicated ? '$armName (Safe Arm)' : armName;
            final formattedTime =
                '${log.recordedAt.year}-${log.recordedAt.month.toString().padLeft(2, '0')}-${log.recordedAt.day.toString().padLeft(2, '0')} ${log.recordedAt.hour.toString().padLeft(2, '0')}:${log.recordedAt.minute.toString().padLeft(2, '0')}';

            return Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${log.systolic}/${log.diastolic} mmHg',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  chipLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              if (log.isPairedAssessment) ...[
                                const SizedBox(width: 6),
                                Chip(
                                  label: Text(
                                    log.pairedRole == 'baseline'
                                        ? 'Baseline (Paired)'
                                        : 'Follow-Up (+${log.elapsedMinutes ?? 0}m)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                  backgroundColor: theme.colorScheme.tertiaryContainer,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pulse: ${log.pulse} bpm  •  $formattedTime',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (log.isPairedAssessment && log.pairedRole == 'followUp' && log.systolicDelta != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Hemodynamic Delta: ${log.systolicDelta! > 0 ? "+" : ""}${log.systolicDelta}/${log.diastolicDelta! > 0 ? "+" : ""}${log.diastolicDelta} mmHg • Pulse: ${log.pulseDelta != null && log.pulseDelta! > 0 ? "+" : ""}${log.pulseDelta} bpm',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => Text('Error loading trends: $e'),
    );
  }
}
