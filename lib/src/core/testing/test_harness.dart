import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

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
      actualFluidRemovedMl: drift.Value(actualFluidRemovedMl),
      notes: drift.Value(notes),
      symptoms: drift.Value(symptoms),
    );
    await database.into(database.dialysisSessions).insert(companion);
    return (database.select(database.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).getSingle();
  }

  /// Clinical helper to log Blood Pressure with arm validation.
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
    final bpId = id ?? generateUuid();
    final companion = BloodPressureLogsCompanion.insert(
      id: drift.Value(bpId),
      patientId: patientId,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      armUsed: armUsed,
      isSafeArm: drift.Value(isSafeArm),
      recordedAt: recordedAt,
    );
    await database.into(database.bloodPressureLogs).insert(companion);
    return (database.select(database.bloodPressureLogs)..where((tbl) => tbl.id.equals(bpId))).getSingle();
  }

  /// Clinical helper to log Fluid Intake.
  Future<FluidIntakeLog> recordFluidIntake({
    String? id,
    required String patientId,
    required int volumeMl,
    required String beverageType,
    bool phosphateBinderTaken = false,
    required DateTime recordedAt,
  }) async {
    final intakeId = id ?? generateUuid();
    final companion = FluidIntakeLogsCompanion.insert(
      id: drift.Value(intakeId),
      patientId: patientId,
      volumeMl: volumeMl,
      beverageType: beverageType,
      phosphateBinderTaken: drift.Value(phosphateBinderTaken),
      recordedAt: recordedAt,
    );
    await database.into(database.fluidIntakeLogs).insert(companion);
    return (database.select(database.fluidIntakeLogs)..where((tbl) => tbl.id.equals(intakeId))).getSingle();
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
    final outputId = id ?? generateUuid();
    final companion = FluidOutputLogsCompanion.insert(
      id: drift.Value(outputId),
      patientId: patientId,
      volumeMl: volumeMl,
      outputType: outputType,
      hematuriaGrade: drift.Value(hematuriaGrade),
      recordedAt: recordedAt,
    );
    await database.into(database.fluidOutputLogs).insert(companion);
    return (database.select(database.fluidOutputLogs)..where((tbl) => tbl.id.equals(outputId))).getSingle();
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
