import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../dialysis/data/dialysis_session_repository.dart';
import '../data/fluid_repository.dart';
import '../domain/fluid_balance_summary.dart';
import 'fluid_intake_entry_screen.dart';
import 'fluid_output_entry_screen.dart';

/// Consolidated Fluid Hub screen presenting 24-hour dual fluid balance,
/// plain-language metrics, allowance progression, and quick logging actions.
class FluidHubScreen extends ConsumerWidget {
  final Patient patient;

  const FluidHubScreen({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(fluidBalance24hStreamProvider(patient.id));
    final intakeLogsAsync = ref.watch(todayFluidIntakeLogsStreamProvider(patient.id));
    final outputLogsAsync = ref.watch(todayFluidOutputLogsStreamProvider(patient.id));
    final dialysisSessionsAsync = ref.watch(dialysisSessionsStreamProvider(patient.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fluid Hub',
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
              // 1. Dual Fluid Balance Overview Cards
              balanceAsync.when(
                data: (summary) => _DualFluidBalanceCards(
                  patient: patient,
                  summary: summary,
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                ),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading fluid balance: $e'),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Quick Action Buttons (Min 48dp touch targets)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52.0,
                      child: ElevatedButton.icon(
                        key: const Key('fluid_hub_log_intake_button'),
                        icon: const Icon(Icons.local_drink_rounded),
                        label: const Text(
                          'Log Fluid Intake',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FluidIntakeEntryScreen(patient: patient),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52.0,
                      child: ElevatedButton.icon(
                        key: const Key('fluid_hub_log_output_button'),
                        icon: const Icon(Icons.opacity_rounded),
                        label: const Text(
                          'Log Fluid Output',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FluidOutputEntryScreen(patient: patient),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. 24-Hour Activity Breakdown
              Text(
                'Today\'s Fluid Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _FluidActivitySection(
                intakeLogsAsync: intakeLogsAsync,
                outputLogsAsync: outputLogsAsync,
                dialysisSessionsAsync: dialysisSessionsAsync,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the three primary Dual Fluid Balance cards in plain language.
class _DualFluidBalanceCards extends StatelessWidget {
  final Patient patient;
  final FluidBalanceSummary summary;

  const _DualFluidBalanceCards({
    required this.patient,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retentionText = summary.bodyFluidRetentionText;
    final removalText = summary.dialysisRemovalText;
    final netText = summary.netBalanceText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Body Fluid Retention (Native Urine Balance)
        Card(
          key: const Key('fluid_hub_retention_card'),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
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
                        Icon(Icons.water_drop_rounded, color: theme.colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Body Fluid Retention',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      retentionText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Natural renal fluid retention before dialysis (Total Intake minus Residual Urine Output).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '24h Intake: ${summary.totalIntakeMl} mL',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '24h Urine Output: ${summary.totalUrineOutputMl} mL',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Card 2: Dialysis Removal (Machine Ultrafiltration)
        Card(
          key: const Key('fluid_hub_dialysis_removal_card'),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
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
                        Icon(Icons.offline_bolt_rounded, color: theme.colorScheme.secondary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Dialysis Removal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      removalText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Machine ultrafiltration extracted during completed dialysis sessions.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Card 3: Net 24-Hour Balance (Dialytic Fluid Balance)
        Card(
          key: const Key('fluid_hub_net_balance_card'),
          elevation: 0,
          color: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
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
                        Icon(Icons.balance_rounded, color: theme.colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Net 24-Hour Balance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      netText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Comprehensive 24-hour hydration volume status after factoring dialysis removal.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Optional Allowance Tracker Card
        if (patient.dailyFluidAllowanceMl != null && patient.dailyFluidAllowanceMl! > 0) ...[
          const SizedBox(height: 12),
          Card(
            key: const Key('fluid_hub_allowance_card'),
            elevation: 0,
            color: theme.colorScheme.surface,
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
                      Text(
                        'Prescribed Fluid Allowance',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        summary.formattedIntakeProgression,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: ((summary.intakePercentageOfAllowance ?? 0) / 100.0).clamp(0.0, 1.0),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: summary.allowanceStatus == FluidAllowanceStatus.exceeded
                        ? theme.colorScheme.error
                        : (summary.allowanceStatus == FluidAllowanceStatus.nearingLimit
                            ? Colors.orange
                            : theme.colorScheme.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.remainingAllowanceMl != null && summary.remainingAllowanceMl! > 0
                        ? '${summary.remainingAllowanceMl} mL remaining today'
                        : 'Prescribed daily allowance reached or exceeded',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Renders today's intake, output, and dialysis ultrafiltration entries.
class _FluidActivitySection extends StatelessWidget {
  final AsyncValue<List<FluidIntakeLog>> intakeLogsAsync;
  final AsyncValue<List<FluidOutputLog>> outputLogsAsync;
  final AsyncValue<List<DialysisSession>> dialysisSessionsAsync;

  const _FluidActivitySection({
    required this.intakeLogsAsync,
    required this.outputLogsAsync,
    required this.dialysisSessionsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intakes = intakeLogsAsync.valueOrNull ?? const [];
    final outputs = outputLogsAsync.valueOrNull ?? const [];
    final sessions = dialysisSessionsAsync.valueOrNull ?? const [];

    final completedSessions = sessions.where((s) => s.status == 'completed' && s.actualFluidRemovedMl != null && s.actualFluidRemovedMl! > 0).toList();

    if (intakes.isEmpty && outputs.isEmpty && completedSessions.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No fluid activity logged today yet.')),
        ),
      );
    }

    return Column(
      children: [
        if (completedSessions.isNotEmpty) ...[
          for (final s in completedSessions)
            Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(Icons.offline_bolt_rounded, color: theme.colorScheme.secondary),
                title: Text('Dialysis Ultrafiltration: -${s.actualFluidRemovedMl} mL'),
                subtitle: Text('Session completed • Started ${s.startedAt.toLocal().hour.toString().padLeft(2, '0')}:${s.startedAt.toLocal().minute.toString().padLeft(2, '0')}'),
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (intakes.isNotEmpty) ...[
          for (final intake in intakes)
            Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(Icons.local_drink_rounded, color: theme.colorScheme.primary),
                title: Text('+${intake.volumeMl} mL (${intake.beverageType})'),
                subtitle: Text('${intake.recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${intake.recordedAt.toLocal().minute.toString().padLeft(2, '0')}${intake.phosphateBinderTaken ? " • Phosphate binder taken" : ""}'),
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (outputs.isNotEmpty) ...[
          for (final output in outputs)
            Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(Icons.opacity_rounded, color: theme.colorScheme.secondary),
                title: Text('-${output.volumeMl} mL (${output.outputType})'),
                subtitle: Text('${output.recordedAt.toLocal().hour.toString().padLeft(2, '0')}:${output.recordedAt.toLocal().minute.toString().padLeft(2, '0')}${output.hematuriaGrade != null ? " • Grade ${output.hematuriaGrade}" : ""}'),
              ),
            ),
        ],
      ],
    );
  }
}
