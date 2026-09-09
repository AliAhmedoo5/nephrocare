import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../profile/domain/clinical_condition.dart';
import '../data/blood_pressure_repository.dart';
import '../domain/paired_bp_assessment_rules.dart';
import '../domain/vascular_safety_rules.dart';

/// Shows the immediate Baseline Blood Pressure measurement prompt upon administering an anti-hypertensive.
Future<void> showBaselineBpPromptDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Patient patient,
  required MedicationAdministration administration,
  required String medicationName,
  required String dosage,
}) async {
  final systolicCtrl = TextEditingController();
  final diastolicCtrl = TextEditingController();
  final pulseCtrl = TextEditingController();
  final intervalCtrl = TextEditingController(
    text: PairedBpAssessmentRules.defaultOnsetWindowMinutes.toString(),
  );

  String selectedArm = patient.safeArm ?? 'leftArm';
  final prohibitedArm = patient.prohibitedArm;
  final isLeftProhibited = prohibitedArm == 'leftArm';
  final isRightProhibited = prohibitedArm == 'rightArm';

  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final theme = Theme.of(ctx);

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Baseline Blood Pressure',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Anti-hypertensive administered: $medicationName ($dosage).\n'
                      'Record immediate baseline reading to schedule 30-min pharmacological response alarm.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Arm Selection with Fistula Arm Safety Flag Lockout
                  Text(
                    'Measurement Arm (Verified Safe Arm)',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('paired_baseline_arm_left'),
                          icon: Icon(isLeftProhibited ? Icons.lock_outline : Icons.check_circle_outline, size: 16),
                          label: Text(isLeftProhibited ? 'Left (Locked)' : 'Left Arm'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedArm == 'leftArm' ? theme.colorScheme.primaryContainer : null,
                            foregroundColor: isLeftProhibited
                                ? theme.colorScheme.outline
                                : (selectedArm == 'leftArm' ? theme.colorScheme.onPrimaryContainer : null),
                          ),
                          onPressed: isLeftProhibited ? null : () => setDialogState(() => selectedArm = 'leftArm'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('paired_baseline_arm_right'),
                          icon: Icon(isRightProhibited ? Icons.lock_outline : Icons.check_circle_outline, size: 16),
                          label: Text(isRightProhibited ? 'Right (Locked)' : 'Right Arm'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedArm == 'rightArm' ? theme.colorScheme.primaryContainer : null,
                            foregroundColor: isRightProhibited
                                ? theme.colorScheme.outline
                                : (selectedArm == 'rightArm' ? theme.colorScheme.onPrimaryContainer : null),
                          ),
                          onPressed: isRightProhibited ? null : () => setDialogState(() => selectedArm = 'rightArm'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Systolic Field
                  TextFormField(
                    key: const Key('paired_baseline_systolic_input'),
                    controller: systolicCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Baseline Systolic (mmHg) *',
                      hintText: 'e.g., 160',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter systolic';
                      final n = int.tryParse(val.trim());
                      if (n == null || n < 50 || n > 300) return 'Valid: 50-300 mmHg';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Diastolic Field
                  TextFormField(
                    key: const Key('paired_baseline_diastolic_input'),
                    controller: diastolicCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Baseline Diastolic (mmHg) *',
                      hintText: 'e.g., 95',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter diastolic';
                      final n = int.tryParse(val.trim());
                      if (n == null || n < 30 || n > 200) return 'Valid: 30-200 mmHg';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Pulse Field
                  TextFormField(
                    key: const Key('paired_baseline_pulse_input'),
                    controller: pulseCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Baseline Pulse (bpm) *',
                      hintText: 'e.g., 82',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter pulse';
                      final n = int.tryParse(val.trim());
                      if (n == null || n < 30 || n > 220) return 'Valid: 30-220 bpm';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Onset window interval
                  TextFormField(
                    key: const Key('paired_baseline_interval_input'),
                    controller: intervalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Onset Window Alarm (20–35 min)',
                      hintText: '30',
                      suffixText: 'min',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter minutes';
                      final n = int.tryParse(val.trim());
                      if (n == null || !PairedBpAssessmentRules.isValidOnsetWindow(n)) {
                        return 'Window must be 20–35 minutes';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Skip For Now'),
            ),
            ElevatedButton(
              key: const Key('save_paired_baseline_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final sys = int.parse(systolicCtrl.text.trim());
                final dia = int.parse(diastolicCtrl.text.trim());
                final pulse = int.parse(pulseCtrl.text.trim());
                final interval = int.parse(intervalCtrl.text.trim());

                try {
                  await ref.read(bloodPressureRepositoryProvider).recordBaselineBloodPressure(
                        patientId: patient.id,
                        medicationAdministrationId: administration.id,
                        medicationName: medicationName,
                        systolic: sys,
                        diastolic: dia,
                        pulse: pulse,
                        armUsed: selectedArm,
                        onsetWindowMinutes: interval,
                      );

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Baseline BP logged ($sys/$dia mmHg). Background alarm scheduled for $interval min.',
                        ),
                        backgroundColor: theme.colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error recording baseline: $e'),
                        backgroundColor: theme.colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Baseline & Set Alarm'),
            ),
          ],
        );
      },
    ),
  );
}

/// Shows the Follow-Up Blood Pressure prompt pre-populated with baseline reference values.
Future<void> showFollowUpBpPromptDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Patient patient,
  required BloodPressureLog baseline,
  String? medicationName,
}) async {
  final systolicCtrl = TextEditingController(text: baseline.systolic.toString());
  final diastolicCtrl = TextEditingController(text: baseline.diastolic.toString());
  final pulseCtrl = TextEditingController(text: baseline.pulse.toString());

  final prohibitedArm = patient.prohibitedArm;
  String selectedArm = patient.safeArm ?? (baseline.armUsed != prohibitedArm ? baseline.armUsed : 'leftArm');
  final isLeftProhibited = prohibitedArm == 'leftArm';
  final isRightProhibited = prohibitedArm == 'rightArm';

  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final theme = Theme.of(ctx);
        final elapsedSinceBaseline = DateTime.now().toUtc().difference(baseline.recordedAt).inMinutes;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.alarm_on_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Follow-Up Blood Pressure',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Baseline Reference Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baseline Reference Values',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${baseline.systolic}/${baseline.diastolic} mmHg  •  Pulse: ${baseline.pulse} bpm\n'
                          'Arm: ${AccessLocation.fromString(baseline.armUsed)?.displayName ?? baseline.armUsed}  •  '
                          '${elapsedSinceBaseline > 0 ? '$elapsedSinceBaseline min ago' : 'Just now'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Arm Selection
                  Text(
                    'Measurement Arm',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('paired_followup_arm_left'),
                          icon: Icon(isLeftProhibited ? Icons.lock_outline : Icons.check_circle_outline, size: 16),
                          label: Text(isLeftProhibited ? 'Left (Locked)' : 'Left Arm'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedArm == 'leftArm' ? theme.colorScheme.primaryContainer : null,
                            foregroundColor: isLeftProhibited
                                ? theme.colorScheme.outline
                                : (selectedArm == 'leftArm' ? theme.colorScheme.onPrimaryContainer : null),
                          ),
                          onPressed: isLeftProhibited ? null : () => setDialogState(() => selectedArm = 'leftArm'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('paired_followup_arm_right'),
                          icon: Icon(isRightProhibited ? Icons.lock_outline : Icons.check_circle_outline, size: 16),
                          label: Text(isRightProhibited ? 'Right (Locked)' : 'Right Arm'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selectedArm == 'rightArm' ? theme.colorScheme.primaryContainer : null,
                            foregroundColor: isRightProhibited
                                ? theme.colorScheme.outline
                                : (selectedArm == 'rightArm' ? theme.colorScheme.onPrimaryContainer : null),
                          ),
                          onPressed: isRightProhibited ? null : () => setDialogState(() => selectedArm = 'rightArm'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Follow-Up Systolic
                  TextFormField(
                    key: const Key('paired_followup_systolic_input'),
                    controller: systolicCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Follow-Up Systolic (mmHg) *',
                      hintText: 'e.g., 135',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter systolic';
                      final n = int.tryParse(val.trim());
                      if (n == null || n < 50 || n > 300) return 'Valid: 50-300 mmHg';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Follow-Up Diastolic
                  TextFormField(
                    key: const Key('paired_followup_diastolic_input'),
                    controller: diastolicCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Follow-Up Diastolic (mmHg) *',
                      hintText: 'e.g., 82',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter diastolic';
                      final n = int.tryParse(val.trim());
                      if (n == null || n < 30 || n > 200) return 'Valid: 30-200 mmHg';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Follow-Up Pulse
                  TextFormField(
                    key: const Key('paired_followup_pulse_input'),
                    controller: pulseCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Follow-Up Pulse (bpm) *',
                      hintText: 'e.g., 74',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter pulse';
                      final n = int.tryParse(val.trim());
                      if (n == null || n < 30 || n > 220) return 'Valid: 30-220 bpm';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('save_paired_followup_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final sys = int.parse(systolicCtrl.text.trim());
                final dia = int.parse(diastolicCtrl.text.trim());
                final pulse = int.parse(pulseCtrl.text.trim());

                try {
                  final result = await ref.read(bloodPressureRepositoryProvider).recordFollowUpBloodPressure(
                        patientId: patient.id,
                        pairedAssessmentId: baseline.pairedAssessmentId ?? baseline.id,
                        systolic: sys,
                        diastolic: dia,
                        pulse: pulse,
                        armUsed: selectedArm,
                      );

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }

                  if (context.mounted) {
                    final sysDelta = result.systolicDelta ?? 0;
                    final diaDelta = result.diastolicDelta ?? 0;
                    final signSys = sysDelta > 0 ? '+' : '';
                    final signDia = diaDelta > 0 ? '+' : '';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Follow-up recorded! Elapsed: ${result.elapsedMinutes}m. '
                          'Deltas: $signSys$sysDelta/$signDia$diaDelta mmHg.',
                        ),
                        backgroundColor: theme.colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error recording follow-up: $e'),
                        backgroundColor: theme.colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Follow-Up'),
            ),
          ],
        );
      },
    ),
  );
}
