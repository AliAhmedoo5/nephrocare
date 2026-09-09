import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../blood_pressure/data/blood_pressure_repository.dart';
import '../../blood_pressure/domain/vascular_safety_rules.dart';
import '../../blood_pressure/presentation/blood_pressure_entry_screen.dart';
import '../../blood_pressure/presentation/paired_bp_dialogs.dart';
import '../../catheter/data/catheter_repository.dart';
import '../../catheter/presentation/catheter_lifespan_screen.dart';
import '../../dialysis/data/dialysis_session_repository.dart';
import '../../dialysis/presentation/access_inspection_history_screen.dart';
import '../../dialysis/presentation/hemodialysis_check_in_screen.dart';
import '../../dialysis/presentation/hemodialysis_post_session_screen.dart';
import '../../dialysis/presentation/peritoneal_exchange_screen.dart';
import '../../dialysis/presentation/weight_trends_screen.dart';
import '../../fluid/data/fluid_repository.dart';
import '../../fluid/presentation/fluid_hub_screen.dart';
import '../../fluid/presentation/fluid_intake_entry_screen.dart';
import '../../fluid/presentation/fluid_output_entry_screen.dart';
import '../../medications/data/medication_repository.dart';
import '../../medications/presentation/medication_screen.dart';
import '../../profile/domain/clinical_condition.dart';
import '../../profile/presentation/patient_profile_setup_screen.dart';
import '../../profile/presentation/profile_management_screen.dart';
import '../../reports/presentation/modular_clinical_report_screen.dart';
import '../../sync/presentation/offline_peer_sync_screen.dart';
import '../../clinical_terms_guide/presentation/caregiver_terms_guide_screen.dart';
import '../../clinical_terms_guide/presentation/clinical_info_trigger.dart';
import 'condition_adaptive_grid.dart';
import 'symptom_log_screen.dart';

/// Primary dashboard screen rendering the Condition-Adaptive Grid and patient safety indicators.
class DashboardScreen extends ConsumerWidget {
  final Patient patient;

  const DashboardScreen({
    super.key,
    required this.patient,
  });

  void _openCaregiverTermsGuide(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CaregiverTermsGuideScreen(),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PatientProfileSetupScreen(
          existingPatient: patient,
        ),
      ),
    );
  }

  void _openProfileManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileManagementScreen(),
      ),
    );
  }

  void _openModularClinicalReport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModularClinicalReportScreen(patient: patient),
      ),
    );
  }

  void _openOfflinePeerSync(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OfflinePeerSyncScreen(patient: patient),
      ),
    );
  }

  void _openCatheterLifespan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CatheterLifespanScreen(patient: patient),
      ),
    );
  }

  void _openMedicationScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicationScreen(patient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final condition = ClinicalCondition.fromString(patient.diagnosis) ?? ClinicalCondition.hemodialysis;
    final accessLocation = AccessLocation.fromString(patient.fistulaArmLocation);
    final isFistulaArmActive = patient.hasArmAccess;
    final fluidBalanceAsync = ref.watch(fluidBalance24hStreamProvider(patient.id));
    final fluidSummary = fluidBalanceAsync.valueOrNull;
    final catheterSummaryAsync = ref.watch(catheterLifespanSummaryStreamProvider(patient.id));
    final catheterSummary = catheterSummaryAsync.valueOrNull;
    final activeMedsAsync = ref.watch(activeMedicationsStreamProvider(patient.id));
    final activeMeds = activeMedsAsync.valueOrNull ?? const [];
    final activeSessionAsync = ref.watch(activeDialysisSessionStreamProvider(patient.id));
    final activeSession = activeSessionAsync.valueOrNull;
    final pendingFollowUpsAsync = ref.watch(pendingFollowUpAssessmentsStreamProvider(patient.id));
    final pendingFollowUps = pendingFollowUpsAsync.valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NephroCare',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            key: const Key('open_medications_button'),
            icon: const Icon(Icons.medication_rounded),
            tooltip: 'Medication Regimen & Administrations',
            onPressed: () => _openMedicationScreen(context),
          ),
          IconButton(
            key: const Key('open_catheter_button'),
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Urine Foley Catheter Lifespan',
            onPressed: () => _openCatheterLifespan(context),
          ),
          IconButton(
            key: const Key('open_peer_sync_button'),
            icon: const Icon(Icons.sync_alt_rounded),
            tooltip: 'Offline Peer-to-Peer Sync',
            onPressed: () => _openOfflinePeerSync(context),
          ),
          IconButton(
            key: const Key('open_reports_button'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Modular Clinical Report',
            onPressed: () => _openModularClinicalReport(context),
          ),
          IconButton(
            key: const Key('open_terms_guide_button'),
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Caregiver & Clinical Terms Guide',
            onPressed: () => _openCaregiverTermsGuide(context),
          ),
          IconButton(
            key: const Key('manage_profiles_button'),
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Profiles & Caregiver Mirrors',
            onPressed: () => _openProfileManagement(context),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'Edit Patient Profile',
            onPressed: () => _editProfile(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.cloud_off_rounded,
              semanticLabel: 'Offline-First Active',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Patient Profile Summary Header Card
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Chip(
                                      label: Text(
                                        condition.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    if (patient.isCaregiverMirror)
                                      Container(
                                        key: const Key('caregiver_mirror_badge'),
                                        child: Chip(
                                          avatar: const Icon(Icons.visibility_outlined, size: 16),
                                          label: const Text(
                                            'Caregiver Mirror',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: theme.colorScheme.secondaryContainer,
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton.outlined(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit Profile',
                            onPressed: () => _editProfile(context),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (patient.prescribedDryWeightKg != null)
                            _MetricItem(
                              icon: Icons.monitor_weight_outlined,
                              label: 'Prescribed Dry Weight',
                              value: '${patient.prescribedDryWeightKg} kg',
                            ),
                          if (patient.dailyFluidAllowanceMl != null)
                            _MetricItem(
                              icon: Icons.water_drop_outlined,
                              label: 'Daily Fluid Allowance',
                              value: '${patient.dailyFluidAllowanceMl} mL',
                            ),
                          if (fluidSummary != null)
                            _MetricItem(
                              icon: Icons.balance_rounded,
                              label: '24-Hour Fluid Balance',
                              value: '${fluidSummary.netBalanceMl >= 0 ? '+' : ''}${fluidSummary.netBalanceMl} mL',
                            ),
                          if (catheterSummary != null)
                            InkWell(
                              key: const Key('dashboard_catheter_metric_tile'),
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _openCatheterLifespan(context),
                              child: _MetricItem(
                                icon: Icons.timer_outlined,
                                label: 'Foley Catheter',
                                value: 'Day ${catheterSummary.dayOfCycle} of ${catheterSummary.totalLifespanDays}',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Fistula Arm Safety Flag Banner per ADR-0003
              if (isFistulaArmActive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Fistula Arm Safety Flag Active',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const ClinicalInfoTrigger(
                                  key: Key('dashboard_fistula_safety_info_trigger'),
                                  termId: 'fistula_arm_safety',
                                  iconSize: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${accessLocation?.displayName ?? 'Designated arm'} bearing vascular access. Prohibited for blood pressure cuffs, blood draws, and IV placement.',
                              style: theme.textTheme.bodySmall?.copyWith(
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
              ],

              // 3. CAUTI Risk Window Banner per CONTEXT.md
              if (catheterSummary != null && catheterSummary.isCautiRiskActive) ...[
                const SizedBox(height: 12),
                InkWell(
                  key: const Key('dashboard_cauti_risk_alert'),
                  onTap: () => _openCatheterLifespan(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.onErrorContainer,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'CAUTI Risk Window Active',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: theme.colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const ClinicalInfoTrigger(
                                    key: Key('dashboard_cauti_risk_info_trigger'),
                                    termId: 'cauti_risk_window',
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Indwelling Foley catheter exceeded ${catheterSummary.totalLifespanDays}-day lifespan (${catheterSummary.daysOverdue} day${catheterSummary.daysOverdue == 1 ? '' : 's'} past due). Timely replacement mandated to avoid infection.',
                                style: theme.textTheme.bodySmall?.copyWith(
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
                ),
              ],

              // 4. Active In-Progress Dialysis Session Banner per Issue #15
              if (activeSession != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('active_dialysis_session_banner'),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_filled_rounded,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dialysis Session In Progress',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Started at ${activeSession.startedAt.toLocal().hour.toString().padLeft(2, '0')}:${activeSession.startedAt.toLocal().minute.toString().padLeft(2, '0')} • Pre-Weight: ${activeSession.preWeightKg != null ? "${activeSession.preWeightKg} kg" : "--"}${activeSession.calculatedUltrafiltrationGoalMl != null ? " • UF Goal: ${activeSession.calculatedUltrafiltrationGoalMl} mL" : ""}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
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
                        height: 48,
                        child: ElevatedButton.icon(
                          key: const Key('resume_dialysis_session_button'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => HemodialysisPostSessionScreen(
                                  patient: patient,
                                  existingSession: activeSession,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text(
                            'Resume Session / Checkout',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Paired Anti-Hypertensive Follow-Up BP Alert Card
              if (pendingFollowUps.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DashboardPairedBpPendingCard(
                  patient: patient,
                  pendingBaselines: pendingFollowUps,
                ),
              ],

              // 5. Quick Medication Administration (1-Tap)
              if (activeMeds.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DashboardQuickMedicationsCard(
                  patient: patient,
                  medications: activeMeds,
                  onOpenMedicationScreen: () => _openMedicationScreen(context),
                ),
              ],

              const SizedBox(height: 20),

              // Section Header
              Text(
                'Clinical Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 5. Condition-Adaptive Grid (Exactly 6 Cards)
              ConditionAdaptiveGrid(
                conditionName: patient.diagnosis,
                fluidSummary: fluidSummary,
                catheterSummary: catheterSummary,
                activeMedicationsCount: activeMeds.length,
                hasActiveDialysisSession: activeSession != null,
                onCardTap: (card) {
                  if (card.title == 'Unified Dialysis Session' ||
                      card.id == 'hd_dialysis_session' ||
                      card.id == 'hd_check_in' ||
                      card.title == 'Check-in') {
                    if (activeSession != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HemodialysisPostSessionScreen(
                            patient: patient,
                            existingSession: activeSession,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HemodialysisCheckInScreen(
                            patient: patient,
                          ),
                        ),
                      );
                    }
                  } else if (card.id == 'hd_post_dialysis' || card.title == 'Post-Dialysis Log') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HemodialysisPostSessionScreen(
                          patient: patient,
                          existingSession: activeSession,
                        ),
                      ),
                    );
                  } else if (card.title.contains('Blood Pressure') || card.id.contains('blood_pressure')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BloodPressureEntryScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  } else if (card.id == 'hd_catheter_access' ||
                      card.title == 'Catheter & Access Monitor' ||
                      card.id == 'pd_exit_site' ||
                      card.title.contains('Exit-Site') ||
                      card.title.contains('Access Inspection')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AccessInspectionHistoryScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  } else if (card.id == 'uro_catheter_lifespan' ||
                      card.title.contains('Foley Catheter') ||
                      card.title.contains('Catheter Lifespan')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CatheterLifespanScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  } else if (card.id.contains('medication') ||
                      card.title.contains('Medication')) {
                    _openMedicationScreen(context);
                  } else if (card.id.contains('fluid_hub') ||
                      card.title == 'Fluid Hub' ||
                      card.title.contains('Fluid Hub')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FluidHubScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  } else if (card.id == 'hd_fluid_intake' ||
                      card.id == 'ckd_fluid_allowance' ||
                      card.id == 'uro_fluid_intake' ||
                      card.title.contains('Fluid Intake') ||
                      card.title.contains('Fluid Allowance')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FluidIntakeEntryScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  } else if (card.id == 'hd_fluid_output' ||
                      card.id == 'pd_fluid_balance' ||
                      card.id == 'uro_urine_evacuation' ||
                      card.title.contains('Fluid Output') ||
                      card.title.contains('Urine Evacuation') ||
                      card.title.contains('Fluid Balance')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FluidOutputEntryScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  } else if (card.id.contains('clinical_report') ||
                      card.title.contains('Modular Clinical Report') ||
                      card.title.contains('Clinical Report')) {
                    _openModularClinicalReport(context);
                  } else if (card.id == 'pd_daily_weight' ||
                      card.id == 'ckd_daily_weight' ||
                      card.title.contains('Daily Weight') ||
                      card.title.contains('Weight & Dry Weight')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WeightTrendsScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  } else if (card.id == 'pd_exchange_log' ||
                      card.title.contains('Exchange Log') ||
                      card.title.contains('Exchange')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PeritonealExchangeScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  } else if (card.id == 'ckd_symptom_log' ||
                      card.id == 'uro_symptom_log' ||
                      card.title.contains('Symptom Log')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SymptomLogScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening ${card.title}...'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quick 1-tap medication administration card on Dashboard.
class _DashboardQuickMedicationsCard extends ConsumerWidget {
  final Patient patient;
  final List<Medication> medications;
  final VoidCallback onOpenMedicationScreen;

  const _DashboardQuickMedicationsCard({
    required this.patient,
    required this.medications,
    required this.onOpenMedicationScreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      key: const Key('dashboard_quick_medications_card'),
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
                    Icon(Icons.medication_rounded, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Medication Dose',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onOpenMedicationScreen,
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: medications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final med = medications[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${med.dosage} • ${med.frequency}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          key: Key('dashboard_quick_take_${med.id}'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Take', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final admin = await ref.read(medicationRepositoryProvider).recordAdministration(
                                  patientId: patient.id,
                                  medicationId: med.id,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Administered ${med.name} (${med.dosage})'),
                                  backgroundColor: theme.colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              if (med.isAntiHypertensive) {
                                await showBaselineBpPromptDialog(
                                  context: context,
                                  ref: ref,
                                  patient: patient,
                                  administration: admin,
                                  medicationName: med.name,
                                  dosage: med.dosage,
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Alert card indicating a pending follow-up blood pressure measurement for an anti-hypertensive dose.
class _DashboardPairedBpPendingCard extends ConsumerWidget {
  final Patient patient;
  final List<BloodPressureLog> pendingBaselines;

  const _DashboardPairedBpPendingCard({
    required this.patient,
    required this.pendingBaselines,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final baseline = pendingBaselines.first;
    final armName = AccessLocation.fromString(baseline.armUsed)?.displayName ?? baseline.armUsed;
    final elapsed = DateTime.now().toUtc().difference(baseline.recordedAt).inMinutes;

    return Card(
      key: const Key('dashboard_paired_bp_alert_card'),
      color: theme.colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.tertiary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm_on_rounded, color: theme.colorScheme.onTertiaryContainer, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Follow-Up Blood Pressure Due',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                      Text(
                        'Baseline: ${baseline.systolic}/${baseline.diastolic} mmHg (${baseline.pulse} bpm) on $armName • ${elapsed > 0 ? "$elapsed min ago" : "Just now"}',
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
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('dashboard_log_paired_followup_button'),
                icon: const Icon(Icons.favorite_rounded),
                label: const Text(
                  'Log Follow-Up Blood Pressure',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  showFollowUpBpPromptDialog(
                    context: context,
                    ref: ref,
                    patient: patient,
                    baseline: baseline,
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


