import '../../../core/database/app_database.dart';
import '../../blood_pressure/domain/paired_bp_assessment.dart';
import '../../catheter/domain/catheter_lifespan_rules.dart';
import '../../fluid/domain/fluid_balance_summary.dart';
import 'clinical_report_config.dart';

/// Clinical aggregate summarizing dual fluid dynamics over the report observation window:
/// explicitly separating native residual urine output from machine ultrafiltration.
class DualFluidBalanceSummary {
  final int totalIntakeMl;
  final int totalUrineOutputMl;
  final int machineUltrafiltrationMl;
  final int totalOutputMl;
  final int bodyFluidRetentionMl;
  final int dialyticExtractionMl;
  final int netDialyticBalanceMl;
  final int intakeLogCount;
  final int urineOutputLogCount;
  final int dialysisSessionCount;

  const DualFluidBalanceSummary({
    required this.totalIntakeMl,
    required this.totalUrineOutputMl,
    required this.machineUltrafiltrationMl,
    required this.totalOutputMl,
    required this.bodyFluidRetentionMl,
    required this.dialyticExtractionMl,
    required this.netDialyticBalanceMl,
    this.intakeLogCount = 0,
    this.urineOutputLogCount = 0,
    this.dialysisSessionCount = 0,
  });

  /// Formatted body fluid retention text (e.g., "+350 mL" or "-200 mL").
  String get bodyFluidRetentionText {
    final sign = bodyFluidRetentionMl >= 0 ? '+' : '-';
    return '$sign${FluidBalanceSummary.formatVolume(bodyFluidRetentionMl.abs())} mL';
  }

  /// Formatted dialysis extraction text (e.g., "-2,000 mL" or "0 mL").
  String get dialysisRemovalText {
    return machineUltrafiltrationMl > 0
        ? '-${FluidBalanceSummary.formatVolume(machineUltrafiltrationMl)} mL'
        : '0 mL';
  }

  /// Formatted net dialytic fluid balance text (e.g., "-1,650 mL" or "+350 mL").
  String get netBalanceText {
    final sign = netDialyticBalanceMl >= 0 ? '+' : '-';
    return '$sign${FluidBalanceSummary.formatVolume(netDialyticBalanceMl.abs())} mL';
  }

  /// Plain-language clinical summary displaying Body Fluid Retention, Dialysis Removal, and Net Balance.
  String get plainLanguageSummary {
    return 'Body Fluid Retention: $bodyFluidRetentionText | Dialysis Removal: $dialysisRemovalText | Net Balance: $netBalanceText';
  }
}

/// Aggregated domain data container representing the clinical dataset
/// for a Modular Clinical Report across the selected observation date window.
class ClinicalReportData {
  final Patient patient;
  final ModularReportConfig config;
  final DateWindowRange dateRange;
  final DateTime generatedAt;
  final List<DialysisSession> dialysisSessions;
  final List<BloodPressureLog> bloodPressureLogs;
  final List<FluidIntakeLog> fluidIntakeLogs;
  final List<FluidOutputLog> fluidOutputLogs;
  final FluidBalanceSummary? fluidBalanceSummary;
  final List<AccessInspection> accessInspections;
  final List<CatheterEvent> catheterEvents;
  final CatheterLifespanSummary? catheterLifespanSummary;
  final List<PairedBpAssessment> pairedBpAssessments;
  final DualFluidBalanceSummary? dualFluidBalanceSummary;
  final List<Medication> medications;
  final List<MedicationAdministration> medicationAdministrations;

  const ClinicalReportData({
    required this.patient,
    required this.config,
    required this.dateRange,
    required this.generatedAt,
    this.dialysisSessions = const [],
    this.bloodPressureLogs = const [],
    this.fluidIntakeLogs = const [],
    this.fluidOutputLogs = const [],
    this.fluidBalanceSummary,
    this.accessInspections = const [],
    this.catheterEvents = const [],
    this.catheterLifespanSummary,
    this.pairedBpAssessments = const [],
    this.dualFluidBalanceSummary,
    this.medications = const [],
    this.medicationAdministrations = const [],
  });
}

