import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/hemodialysis_calculation_rules.dart';

/// Repository managing hemodialysis pre-session check-ins, post-session logging,
/// vascular access inspections, and reactive stream subscriptions.
class DialysisSessionRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DialysisSessionRepository(this._db);

  /// Records a pre-dialysis check-in session in Drift SQLite.
  ///
  /// Automatically computes Interdialytic Weight Gain against previous completed session
  /// and Ultrafiltration Goal against Prescribed Dry Weight with volume allowances.
  /// Also persists vascular access inspection if inspection parameters are supplied.
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
    // 1. Fetch patient profile
    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }

    // 2. Query previous completed session to get previous postWeightKg
    final previousSession = await (_db.select(_db.dialysisSessions)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.postWeightKg.isNotNull())
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.startedAt)])
          ..limit(1))
        .getSingleOrNull();

    final previousPostWeight = previousSession?.postWeightKg;
    final dryWeight = patient.prescribedDryWeightKg ?? preWeightKg;

    // 3. Compute Interdialytic Weight Gain and Ultrafiltration Goal
    final idwg = HemodialysisCalculationRules.calculateInterdialyticWeightGain(
      currentPreWeightKg: preWeightKg,
      previousPostWeightKg: previousPostWeight,
      prescribedDryWeightKg: dryWeight,
    );

    final ufGoal = HemodialysisCalculationRules.calculateUltrafiltrationGoal(
      currentPreWeightKg: preWeightKg,
      prescribedDryWeightKg: dryWeight,
      volumeAllowanceMl: volumeAllowanceMl,
    );

    final sessionId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final sessionStartTime = startedAt?.toUtc() ?? now;

    // 4. Insert DialysisSession
    final sessionCompanion = DialysisSessionsCompanion.insert(
      id: drift.Value(sessionId),
      patientId: patientId,
      sessionType: 'hemodialysis',
      startedAt: sessionStartTime,
      preWeightKg: drift.Value(preWeightKg),
      calculatedInterdialyticWeightGainKg: drift.Value(idwg),
      calculatedUltrafiltrationGoalMl: drift.Value(ufGoal),
      notes: drift.Value(notes),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.dialysisSessions).insert(sessionCompanion);

    // 5. Insert AccessInspection if inspection details or patient access type exist
    final accessType = patient.vascularAccessType ?? 'none';
    final location = patient.fistulaArmLocation ?? 'unknown';

    final inspectionCompanion = AccessInspectionsCompanion.insert(
      id: drift.Value(_uuid.v4()),
      patientId: patientId,
      accessType: accessType,
      anatomicalLocation: location,
      thrillPresent: drift.Value(thrillPresent),
      bruitPresent: drift.Value(bruitPresent),
      rednessPresent: drift.Value(rednessPresent),
      swellingPresent: drift.Value(swellingPresent),
      dischargePresent: drift.Value(dischargePresent),
      painPresent: drift.Value(painPresent),
      notes: drift.Value(inspectionNotes),
      recordedAt: sessionStartTime,
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    await _db.into(_db.accessInspections).insert(inspectionCompanion);

    return (_db.select(_db.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).getSingle();
  }

  /// Records post-dialysis session metrics and completes the session.
  ///
  /// Computes difference from Prescribed Dry Weight and records post-treatment symptoms.
  Future<DialysisSession> recordPostDialysisSession({
    required String sessionId,
    required double postWeightKg,
    int? actualFluidRemovedMl,
    List<String>? symptoms,
    String? notes,
    DateTime? endedAt,
  }) async {
    final session = await (_db.select(_db.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).getSingleOrNull();
    if (session == null) {
      throw ArgumentError('Dialysis session not found with id: $sessionId');
    }

    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(session.patientId))).getSingleOrNull();
    final dryWeight = patient?.prescribedDryWeightKg ?? postWeightKg;

    final postWeightDiff = HemodialysisCalculationRules.calculatePostWeightDifference(
      postWeightKg: postWeightKg,
      prescribedDryWeightKg: dryWeight,
    );

    final now = DateTime.now().toUtc();
    final sessionEndTime = endedAt?.toUtc() ?? now;
    final symptomsString = (symptoms != null && symptoms.isNotEmpty) ? symptoms.join(', ') : null;

    final updateCompanion = DialysisSessionsCompanion(
      postWeightKg: drift.Value(postWeightKg),
      calculatedPostWeightDifferenceKg: drift.Value(postWeightDiff),
      actualFluidRemovedMl: drift.Value(actualFluidRemovedMl),
      symptoms: drift.Value(symptomsString),
      endedAt: drift.Value(sessionEndTime),
      notes: notes != null ? drift.Value(notes) : const drift.Value.absent(),
      updatedAt: drift.Value(now),
    );

    await (_db.update(_db.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).write(updateCompanion);

    return (_db.select(_db.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).getSingle();
  }

  /// Queries the most recent dialysis session for a patient.
  Future<DialysisSession?> getLatestSession(String patientId) async {
    return (_db.select(_db.dialysisSessions)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Queries all dialysis sessions for a patient ordered most recent first.
  Future<List<DialysisSession>> getSessions(String patientId) async {
    return (_db.select(_db.dialysisSessions)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.startedAt)]))
        .get();
  }

  /// Observes dialysis sessions for a patient reactively.
  Stream<List<DialysisSession>> watchSessions(String patientId) {
    return (_db.select(_db.dialysisSessions)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.startedAt)]))
        .watch();
  }

  /// Queries vascular access inspections for a patient ordered most recent first.
  Future<List<AccessInspection>> getAccessInspections(String patientId) async {
    return (_db.select(_db.accessInspections)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]))
        .get();
  }

  /// Observes vascular access inspections for a patient reactively.
  Stream<List<AccessInspection>> watchAccessInspections(String patientId) {
    return (_db.select(_db.accessInspections)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.recordedAt)]))
        .watch();
  }
}

/// Provider for [DialysisSessionRepository].
final dialysisSessionRepositoryProvider = Provider<DialysisSessionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DialysisSessionRepository(db);
});

/// Stream provider for dialysis sessions of a patient.
final dialysisSessionsStreamProvider = StreamProvider.family<List<DialysisSession>, String>((ref, patientId) {
  final repository = ref.watch(dialysisSessionRepositoryProvider);
  return repository.watchSessions(patientId);
});

/// Stream provider for vascular access inspections of a patient.
final accessInspectionsStreamProvider = StreamProvider.family<List<AccessInspection>, String>((ref, patientId) {
  final repository = ref.watch(dialysisSessionRepositoryProvider);
  return repository.watchAccessInspections(patientId);
});
