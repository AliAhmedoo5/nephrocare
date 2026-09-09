import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../blood_pressure/domain/paired_bp_assessment.dart';
import '../../catheter/data/catheter_repository.dart';
import '../../catheter/domain/catheter_lifespan_rules.dart';
import '../../fluid/data/fluid_repository.dart';
import '../../fluid/domain/fluid_balance_summary.dart';
import '../../fluid/domain/fluid_calculation_rules.dart';
import '../domain/clinical_report_config.dart';
import '../domain/clinical_report_data.dart';

/// Repository responsible for compiling aggregated clinical data slices
/// filtered by observation date window and individually selected clinical modules.
class ClinicalReportRepository {
  final AppDatabase _database;
  final FluidRepository _fluidRepository;
  final CatheterRepository _catheterRepository;

  ClinicalReportRepository(
    this._database, {
    FluidRepository? fluidRepository,
    CatheterRepository? catheterRepository,
  })  : _fluidRepository = fluidRepository ?? FluidRepository(_database),
        _catheterRepository = catheterRepository ?? CatheterRepository(_database);

  /// Compiles a targeted [ClinicalReportData] object for the specified patient,
  /// executing selective queries according to the enabled modules in [config].
  Future<ClinicalReportData> compileReportData({
    required String patientId,
    required ModularReportConfig config,
    DateTime? asOf,
  }) async {
    final patient = await (_database.select(_database.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }

    final now = asOf ?? DateTime.now().toUtc();
    final dateRange = config.resolveDateRange(asOf: now);

    List<DialysisSession> dialysisSessions = const [];
    List<BloodPressureLog> bloodPressureLogs = const [];
    List<FluidIntakeLog> fluidIntakeLogs = const [];
    List<FluidOutputLog> fluidOutputLogs = const [];
    FluidBalanceSummary? fluidSummary;
    List<AccessInspection> accessInspections = const [];
    List<CatheterEvent> catheterEvents = const [];
    CatheterLifespanSummary? catheterSummary;
    List<PairedBpAssessment> pairedBpAssessments = const [];
    DualFluidBalanceSummary? dualFluidSummary;
    List<Medication> medications = const [];
    List<MedicationAdministration> medicationAdministrations = const [];

    // 1. Weight Trends Module
    if (config.isModuleEnabled(ClinicalReportModule.weightTrends)) {
      dialysisSessions = await (_database.select(_database.dialysisSessions)
            ..where((tbl) =>
                tbl.patientId.equals(patientId) &
                tbl.startedAt.isBiggerOrEqualValue(dateRange.start) &
                tbl.startedAt.isSmallerOrEqualValue(dateRange.end))
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.startedAt)]))
          .get();
    }

    // 2. Blood Pressure & Pulse Module
    if (config.isModuleEnabled(ClinicalReportModule.bloodPressureAndPulse)) {
      bloodPressureLogs = await (_database.select(_database.bloodPressureLogs)
            ..where((tbl) =>
                tbl.patientId.equals(patientId) &
                tbl.recordedAt.isBiggerOrEqualValue(dateRange.start) &
                tbl.recordedAt.isSmallerOrEqualValue(dateRange.end))
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]))
          .get();
    }

    // 3. 24-Hour Fluid Balance & Intake Logs Module
    if (config.isModuleEnabled(ClinicalReportModule.fluidBalanceAndIntake)) {
      fluidIntakeLogs = await (_database.select(_database.fluidIntakeLogs)
            ..where((tbl) =>
                tbl.patientId.equals(patientId) &
                tbl.recordedAt.isBiggerOrEqualValue(dateRange.start) &
                tbl.recordedAt.isSmallerOrEqualValue(dateRange.end))
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]))
          .get();

      fluidOutputLogs = await (_database.select(_database.fluidOutputLogs)
            ..where((tbl) =>
                tbl.patientId.equals(patientId) &
                tbl.recordedAt.isBiggerOrEqualValue(dateRange.start) &
                tbl.recordedAt.isSmallerOrEqualValue(dateRange.end))
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]))
          .get();

      fluidSummary = await _fluidRepository.get24HourFluidBalance(patientId, asOf: dateRange.end);
    }

    // 4. Access Inspection & Catheter Lifespan History Module
    if (config.isModuleEnabled(ClinicalReportModule.accessInspectionAndCatheterHistory)) {
      accessInspections = await (_database.select(_database.accessInspections)
            ..where((tbl) =>
                tbl.patientId.equals(patientId) &
                tbl.recordedAt.isBiggerOrEqualValue(dateRange.start) &
                tbl.recordedAt.isSmallerOrEqualValue(dateRange.end))
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]))
          .get();

      // Include in-window catheter events as well as any currently active catheter
      catheterEvents = await (_database.select(_database.catheterEvents)
            ..where((tbl) =>
                tbl.patientId.equals(patientId) &
                (tbl.status.equals('active') |
                    (tbl.insertionDate.isBiggerOrEqualValue(dateRange.start) &
                        tbl.insertionDate.isSmallerOrEqualValue(dateRange.end))))
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.insertionDate)]))
          .get();

      catheterSummary = await _catheterRepository.getCatheterLifespanSummary(patientId, asOf: dateRange.end);
    }

    // 5. Paired Anti-Hypertensive Blood Pressure Table Module
    if (config.isModuleEnabled(ClinicalReportModule.pairedAntiHypertensiveBp)) {
      final pairedLogs = await (_database.select(_database.bloodPressureLogs)
            ..where((tbl) =>
                tbl.patientId.equals(patientId) &
                tbl.isPairedAssessment.equals(true))
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]))
          .get();

      final allPairs = PairedBpAssessment.groupFromLogs(pairedLogs);
      pairedBpAssessments = allPairs
          .where((p) =>
              p.baseline.recordedAt.isAfter(dateRange.start.subtract(const Duration(milliseconds: 1))) &&
              p.baseline.recordedAt.isBefore(dateRange.end.add(const Duration(milliseconds: 1))))
          .toList();
    }

    // 6. Dual Fluid Balance Module
    if (config.isModuleEnabled(ClinicalReportModule.dualFluidBalance)) {
      final intakesForDual = fluidIntakeLogs.isNotEmpty
          ? fluidIntakeLogs
          : await (_database.select(_database.fluidIntakeLogs)
                ..where((tbl) =>
                    tbl.patientId.equals(patientId) &
                    tbl.recordedAt.isBiggerOrEqualValue(dateRange.start) &
                    tbl.recordedAt.isSmallerOrEqualValue(dateRange.end)))
              .get();

      final outputsForDual = fluidOutputLogs.isNotEmpty
          ? fluidOutputLogs
          : await (_database.select(_database.fluidOutputLogs)
                ..where((tbl) =>
                    tbl.patientId.equals(patientId) &
                    tbl.recordedAt.isBiggerOrEqualValue(dateRange.start) &
                    tbl.recordedAt.isSmallerOrEqualValue(dateRange.end)))
              .get();

      final completedSessionsForUf = await (_database.select(_database.dialysisSessions)
            ..where((tbl) =>
                tbl.patientId.equals(patientId) &
                tbl.status.equals('completed') &
                tbl.startedAt.isBiggerOrEqualValue(dateRange.start) &
                tbl.startedAt.isSmallerOrEqualValue(dateRange.end) &
                tbl.actualFluidRemovedMl.isNotNull()))
          .get();

      final totalIntakeMl = intakesForDual.fold<int>(0, (sum, log) => sum + log.volumeMl);
      final totalUrineOutputMl = outputsForDual
          .where((tbl) => tbl.outputType == 'urine')
          .fold<int>(0, (sum, log) => sum + log.volumeMl);
      final manualUfMl = outputsForDual
          .where((tbl) => tbl.outputType == 'ultrafiltration')
          .fold<int>(0, (sum, log) => sum + log.volumeMl);

      int dialysisUfMl = 0;
      int completedSessionsWithUfCount = 0;
      for (final session in completedSessionsForUf) {
        if (session.actualFluidRemovedMl != null && session.actualFluidRemovedMl! > 0) {
          dialysisUfMl += session.actualFluidRemovedMl!;
          completedSessionsWithUfCount++;
        }
      }

      final machineUltrafiltrationMl = dialysisUfMl + manualUfMl;
      final totalOutputMl = totalUrineOutputMl + machineUltrafiltrationMl;
      final bodyFluidRetentionMl = FluidCalculationRules.calculateNativeUrineBalance(
        totalIntakeMl: totalIntakeMl,
        totalUrineOutputMl: totalUrineOutputMl,
      );
      final dialyticExtractionMl = machineUltrafiltrationMl;
      final netDialyticBalanceMl = FluidCalculationRules.calculateDialyticFluidBalance(
        totalIntakeMl: totalIntakeMl,
        totalUrineOutputMl: totalUrineOutputMl,
        machineUltrafiltrationMl: machineUltrafiltrationMl,
      );

      dualFluidSummary = DualFluidBalanceSummary(
        totalIntakeMl: totalIntakeMl,
        totalUrineOutputMl: totalUrineOutputMl,
        machineUltrafiltrationMl: machineUltrafiltrationMl,
        totalOutputMl: totalOutputMl,
        bodyFluidRetentionMl: bodyFluidRetentionMl,
        dialyticExtractionMl: dialyticExtractionMl,
        netDialyticBalanceMl: netDialyticBalanceMl,
        intakeLogCount: intakesForDual.length,
        urineOutputLogCount: outputsForDual.where((tbl) => tbl.outputType == 'urine').length,
        dialysisSessionCount: completedSessionsWithUfCount,
      );
    }

    // 7. Medication Regimen & Adherence Summary Module
    if (config.isModuleEnabled(ClinicalReportModule.medicationRegimenAndAdherence)) {
      medications = await (_database.select(_database.medications)
            ..where((tbl) => tbl.patientId.equals(patientId) & tbl.isActive.equals(true))
            ..orderBy([(tbl) => drift.OrderingTerm.asc(tbl.name)]))
          .get();

      medicationAdministrations = await (_database.select(_database.medicationAdministrations)
            ..where((tbl) =>
                tbl.patientId.equals(patientId) &
                tbl.administeredAt.isBiggerOrEqualValue(dateRange.start) &
                tbl.administeredAt.isSmallerOrEqualValue(dateRange.end))
            ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.administeredAt)]))
          .get();
    }

    // If Paired BP is enabled, ensure linked administrations are available for labeling
    if (pairedBpAssessments.isNotEmpty) {
      final linkedAdminIds = pairedBpAssessments
          .map((p) => p.medicationAdministrationId)
          .whereType<String>()
          .where((id) => !medicationAdministrations.any((a) => a.id == id))
          .toSet();
      if (linkedAdminIds.isNotEmpty) {
        final additionalAdmins = await (_database.select(_database.medicationAdministrations)
              ..where((tbl) => tbl.id.isIn(linkedAdminIds)))
            .get();
        medicationAdministrations = [...medicationAdministrations, ...additionalAdmins];
      }
    }

    return ClinicalReportData(
      patient: patient,
      config: config,
      dateRange: dateRange,
      generatedAt: now,
      dialysisSessions: dialysisSessions,
      bloodPressureLogs: bloodPressureLogs,
      fluidIntakeLogs: fluidIntakeLogs,
      fluidOutputLogs: fluidOutputLogs,
      fluidBalanceSummary: fluidSummary,
      accessInspections: accessInspections,
      catheterEvents: catheterEvents,
      catheterLifespanSummary: catheterSummary,
      pairedBpAssessments: pairedBpAssessments,
      dualFluidBalanceSummary: dualFluidSummary,
      medications: medications,
      medicationAdministrations: medicationAdministrations,
    );
  }
}

/// Riverpod provider for [ClinicalReportRepository].
final clinicalReportRepositoryProvider = Provider<ClinicalReportRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final fluidRepo = ref.watch(fluidRepositoryProvider);
  final catheterRepo = ref.watch(catheterRepositoryProvider);
  return ClinicalReportRepository(
    db,
    fluidRepository: fluidRepo,
    catheterRepository: catheterRepo,
  );
});
