import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../catheter/data/catheter_repository.dart';
import '../../catheter/domain/catheter_lifespan_rules.dart';
import '../../fluid/data/fluid_repository.dart';
import '../../fluid/domain/fluid_balance_summary.dart';
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
