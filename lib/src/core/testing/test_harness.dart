import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../../features/blood_pressure/data/blood_pressure_repository.dart';
import '../../features/dialysis/data/dialysis_session_repository.dart';
import '../../features/fluid/data/fluid_repository.dart';
import '../../features/fluid/domain/fluid_balance_summary.dart';

/// Test harness establishing the Unified Application & State Seam.
///
/// Binds an in-memory Drift SQLite database to a Riverpod [ProviderContainer],
/// providing high-level helper methods to exercise clinical workflows
/// without reaching into database internals or requiring emulator overhead.
class NephroTestHarness {
  final ProviderContainer container;
  final AppDatabase database;
  final Uuid _uuid = const Uuid();

  NephroTestHarness({
    required this.container,
    required this.database,
  });

  /// Generates a RFC 4122 compliant UUIDv4 identifier.
  String generateUuid() => _uuid.v4();

  /// Clinical helper to register a new Patient profile.
  Future<Patient> createPatient({
    String? id,
    required String name,
    required String diagnosis,
    double? prescribedDryWeightKg,
    int? dailyFluidAllowanceMl,
    String? vascularAccessType,
    String? fistulaArmLocation,
    bool isCaregiverMirror = false,
  }) async {
    final patientId = id ?? generateUuid();
    final companion = PatientsCompanion.insert(
      id: drift.Value(patientId),
      name: name,
      diagnosis: diagnosis,
      prescribedDryWeightKg: drift.Value(prescribedDryWeightKg),
      dailyFluidAllowanceMl: drift.Value(dailyFluidAllowanceMl),
      vascularAccessType: drift.Value(vascularAccessType),
      fistulaArmLocation: drift.Value(fistulaArmLocation),
      isCaregiverMirror: drift.Value(isCaregiverMirror),
    );
    await database.into(database.patients).insert(companion);
    return (database.select(database.patients)..where((tbl) => tbl.id.equals(patientId))).getSingle();
  }

  /// Clinical helper to log a Dialysis Session.
  Future<DialysisSession> recordDialysisSession({
    String? id,
    required String patientId,
    required String sessionType,
    required DateTime startedAt,
    DateTime? endedAt,
    double? preWeightKg,
    double? postWeightKg,
    double? calculatedInterdialyticWeightGainKg,
    int? calculatedUltrafiltrationGoalMl,
    double? calculatedPostWeightDifferenceKg,
    int? actualFluidRemovedMl,
    String? notes,
    String? symptoms,
  }) async {
    final sessionId = id ?? generateUuid();
    final companion = DialysisSessionsCompanion.insert(
      id: drift.Value(sessionId),
      patientId: patientId,
      sessionType: sessionType,
      startedAt: startedAt,
      endedAt: drift.Value(endedAt),
      preWeightKg: drift.Value(preWeightKg),
      postWeightKg: drift.Value(postWeightKg),
      calculatedInterdialyticWeightGainKg: drift.Value(calculatedInterdialyticWeightGainKg),
      calculatedUltrafiltrationGoalMl: drift.Value(calculatedUltrafiltrationGoalMl),
      calculatedPostWeightDifferenceKg: drift.Value(calculatedPostWeightDifferenceKg),
      actualFluidRemovedMl: drift.Value(actualFluidRemovedMl),
      notes: drift.Value(notes),
      symptoms: drift.Value(symptoms),
    );
    await database.into(database.dialysisSessions).insert(companion);
    return (database.select(database.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).getSingle();
  }

  /// Clinical helper to perform a pre-dialysis check-in, computing IDWG, UF goal, and logging access inspection.
  Future<DialysisSession> recordPreDialysisCheckIn({
    String? id,
    required String patientId,
    required double preWeightKg,
    int volumeAllowanceMl = 0,
    String? notes,
    DateTime? startedAt,
    bool? thrillPresent,
    bool? bruitPresent,
    bool? rednessPresent,
    bool? swellingPresent,
    bool? dischargePresent,
    bool? painPresent,
    String? inspectionNotes,
  }) async {
    final repository = DialysisSessionRepository(database);
    return repository.recordPreDialysisCheckIn(
      id: id,
      patientId: patientId,
      preWeightKg: preWeightKg,
      volumeAllowanceMl: volumeAllowanceMl,
      notes: notes,
      startedAt: startedAt,
      thrillPresent: thrillPresent,
      bruitPresent: bruitPresent,
      rednessPresent: rednessPresent,
      swellingPresent: swellingPresent,
      dischargePresent: dischargePresent,
      painPresent: painPresent,
      inspectionNotes: inspectionNotes,
    );
  }

  /// Clinical helper to complete a dialysis session with post-weight, variance calculation, and symptoms.
  Future<DialysisSession> recordPostDialysisSession({
    required String sessionId,
    required double postWeightKg,
    int? actualFluidRemovedMl,
    List<String>? symptoms,
    String? notes,
    DateTime? endedAt,
  }) async {
    final repository = DialysisSessionRepository(database);
    return repository.recordPostDialysisSession(
      sessionId: sessionId,
      postWeightKg: postWeightKg,
      actualFluidRemovedMl: actualFluidRemovedMl,
      symptoms: symptoms,
      notes: notes,
      endedAt: endedAt,
    );
  }

  /// Clinical helper to query dialysis sessions for a patient ordered most recent first.
  Future<List<DialysisSession>> getDialysisSessions(String patientId) async {
    return DialysisSessionRepository(database).getSessions(patientId);
  }

  /// Clinical helper to query vascular access inspections for a patient ordered most recent first.
  Future<List<AccessInspection>> getAccessInspections(String patientId) async {
    return DialysisSessionRepository(database).getAccessInspections(patientId);
  }

  /// Clinical helper to log Blood Pressure with arm validation and Fistula Arm Safety Flag enforcement.
  Future<BloodPressureLog> recordBloodPressure({
    String? id,
    required String patientId,
    required int systolic,
    required int diastolic,
    required int pulse,
    required String armUsed,
    bool isSafeArm = true,
    required DateTime recordedAt,
  }) async {
    final repository = BloodPressureRepository(database);
    return repository.recordBloodPressure(
      id: id,
      patientId: patientId,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      armUsed: armUsed,
      recordedAt: recordedAt,
    );
  }

  /// Clinical helper to query hemodynamic blood pressure logs for a patient ordered by recordedAt descending.
  Future<List<BloodPressureLog>> getBloodPressureLogs(String patientId) async {
    return BloodPressureRepository(database).getBloodPressureLogs(patientId);
  }

  /// Alias for [getBloodPressureLogs].
  Future<List<BloodPressureLog>> getHemodynamicTrends(String patientId) => getBloodPressureLogs(patientId);

  /// Clinical helper to log Fluid Intake.
  Future<FluidIntakeLog> recordFluidIntake({
    String? id,
    required String patientId,
    required int volumeMl,
    required String beverageType,
    bool phosphateBinderTaken = false,
    required DateTime recordedAt,
  }) async {
    return FluidRepository(database).recordFluidIntake(
      id: id,
      patientId: patientId,
      volumeMl: volumeMl,
      beverageType: beverageType,
      phosphateBinderTaken: phosphateBinderTaken,
      recordedAt: recordedAt,
    );
  }

  /// Clinical helper to log Fluid Output.
  Future<FluidOutputLog> recordFluidOutput({
    String? id,
    required String patientId,
    required int volumeMl,
    required String outputType,
    int? hematuriaGrade,
    required DateTime recordedAt,
  }) async {
    return FluidRepository(database).recordFluidOutput(
      id: id,
      patientId: patientId,
      volumeMl: volumeMl,
      outputType: outputType,
      hematuriaGrade: hematuriaGrade,
      recordedAt: recordedAt,
    );
  }

  /// Clinical helper to query 24-hour Fluid Balance summary.
  Future<FluidBalanceSummary> get24HourFluidBalance(String patientId, {DateTime? asOf}) {
    return FluidRepository(database).get24HourFluidBalance(patientId, asOf: asOf);
  }

  /// Clinical helper to query fluid intake logs for a patient.
  Future<List<FluidIntakeLog>> getFluidIntakeLogs(String patientId, {DateTime? since}) {
    return FluidRepository(database).getFluidIntakeLogs(patientId, since: since);
  }

  /// Clinical helper to query fluid output logs for a patient.
  Future<List<FluidOutputLog>> getFluidOutputLogs(String patientId, {DateTime? since}) {
    return FluidRepository(database).getFluidOutputLogs(patientId, since: since);
  }

  /// Clinical helper to watch 24-hour Fluid Balance reactively.
  Stream<FluidBalanceSummary> watch24HourFluidBalance(String patientId) {
    return FluidRepository(database).watch24HourFluidBalance(patientId);
  }

  /// Clinical helper to log Catheter Lifecycle Event.
  Future<CatheterEvent> recordCatheterEvent({
    String? id,
    required String patientId,
    required String catheterType,
    required DateTime insertionDate,
    required DateTime replacementDueDate,
    required String status,
    String? notes,
  }) async {
    final catheterId = id ?? generateUuid();
    final companion = CatheterEventsCompanion.insert(
      id: drift.Value(catheterId),
      patientId: patientId,
      catheterType: catheterType,
      insertionDate: insertionDate,
      replacementDueDate: replacementDueDate,
      status: status,
      notes: drift.Value(notes),
    );
    await database.into(database.catheterEvents).insert(companion);
    return (database.select(database.catheterEvents)..where((tbl) => tbl.id.equals(catheterId))).getSingle();
  }

  /// Clinical helper to log Vascular Access Inspection.
  Future<AccessInspection> recordAccessInspection({
    String? id,
    required String patientId,
    required String accessType,
    required String anatomicalLocation,
    bool? thrillPresent,
    bool? bruitPresent,
    bool? rednessPresent,
    bool? swellingPresent,
    bool? dischargePresent,
    bool? painPresent,
    String? notes,
    required DateTime recordedAt,
  }) async {
    final accessId = id ?? generateUuid();
    final companion = AccessInspectionsCompanion.insert(
      id: drift.Value(accessId),
      patientId: patientId,
      accessType: accessType,
      anatomicalLocation: anatomicalLocation,
      thrillPresent: drift.Value(thrillPresent),
      bruitPresent: drift.Value(bruitPresent),
      rednessPresent: drift.Value(rednessPresent),
      swellingPresent: drift.Value(swellingPresent),
      dischargePresent: drift.Value(dischargePresent),
      painPresent: drift.Value(painPresent),
      notes: drift.Value(notes),
      recordedAt: recordedAt,
    );
    await database.into(database.accessInspections).insert(companion);
    return (database.select(database.accessInspections)..where((tbl) => tbl.id.equals(accessId))).getSingle();
  }

  /// Tears down and disposes container and in-memory database connections.
  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}

/// Factory function to construct an isolated [NephroTestHarness] with an in-memory database.
NephroTestHarness createNephroTestHarness() {
  final inMemoryDb = AppDatabase(
    drift.DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(inMemoryDb),
    ],
  );

  return NephroTestHarness(
    container: container,
    database: inMemoryDb,
  );
}
