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
    String sessionType = 'hemodialysis',
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
          ..where((tbl) =>
              tbl.patientId.equals(patientId) &
              tbl.postWeightKg.isNotNull() &
              tbl.status.equals('completed'))
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

    // 4. Insert DialysisSession with inProgress status for hemodialysis
    final sessionCompanion = DialysisSessionsCompanion.insert(
      id: drift.Value(sessionId),
      patientId: patientId,
      sessionType: sessionType,
      startedAt: sessionStartTime,
      preWeightKg: drift.Value(preWeightKg),
      calculatedInterdialyticWeightGainKg: drift.Value(idwg),
      calculatedUltrafiltrationGoalMl: drift.Value(ufGoal),
      status: drift.Value(sessionType == 'hemodialysis' ? 'inProgress' : 'completed'),
      notes: drift.Value(notes),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.dialysisSessions).insert(sessionCompanion);

    // 5. Insert AccessInspection only if inspection details are actually provided
    final hasInspectionData = thrillPresent != null ||
        bruitPresent != null ||
        rednessPresent != null ||
        swellingPresent != null ||
        dischargePresent != null ||
        painPresent != null ||
        (inspectionNotes != null && inspectionNotes.isNotEmpty);

    if (hasInspectionData) {
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
    }

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
      status: const drift.Value('completed'),
      endedAt: drift.Value(sessionEndTime),
      notes: notes != null ? drift.Value(notes) : const drift.Value.absent(),
      updatedAt: drift.Value(now),
    );

    await (_db.update(_db.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).write(updateCompanion);

    return (_db.select(_db.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).getSingle();
  }

  /// Records a daily weight entry in Drift SQLite for continuous fluid and dry weight surveillance.
  Future<DialysisSession> recordDailyWeight({
    String? id,
    required String patientId,
    required double weightKg,
    String? notes,
    DateTime? recordedAt,
  }) async {
    return recordPreDialysisCheckIn(
      id: id,
      patientId: patientId,
      preWeightKg: weightKg,
      sessionType: 'daily_weight',
      notes: notes,
      startedAt: recordedAt,
    );
  }

  /// Records a peritoneal dialysis exchange in Drift SQLite.
  ///
  /// Computes peritoneal ultrafiltration: [drainVolumeMl] - [inflowVolumeMl].
  /// If positive, [actualFluidRemovedMl] captures the net ultrafiltration extracted,
  /// seamlessly feeding the 24-hour Fluid Balance calculation.
  Future<DialysisSession> recordPeritonealExchange({
    String? id,
    required String patientId,
    required int inflowVolumeMl,
    required int drainVolumeMl,
    String? clarity,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }

    if (inflowVolumeMl <= 0) {
      throw ArgumentError('Inflow volume must be greater than zero.');
    }
    if (drainVolumeMl < 0) {
      throw ArgumentError('Drain volume cannot be negative.');
    }

    final exchangeId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final exchangeTime = recordedAt?.toUtc() ?? now;
    final netUf = drainVolumeMl - inflowVolumeMl;
    final actualFluidRemoved = netUf > 0 ? netUf : 0;

    final parts = [
      'Inflow: $inflowVolumeMl mL',
      'Drain: $drainVolumeMl mL',
      'Net UF: ${netUf >= 0 ? "+$netUf" : "$netUf"} mL',
      if (clarity != null && clarity.isNotEmpty) 'Clarity: $clarity',
      if (notes != null && notes.isNotEmpty) notes,
    ];

    final sessionCompanion = DialysisSessionsCompanion.insert(
      id: drift.Value(exchangeId),
      patientId: patientId,
      sessionType: 'peritoneal',
      startedAt: exchangeTime,
      endedAt: drift.Value(exchangeTime),
      actualFluidRemovedMl: drift.Value(actualFluidRemoved),
      notes: drift.Value(parts.join(' | ')),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.dialysisSessions).insert(sessionCompanion);
    return (_db.select(_db.dialysisSessions)..where((tbl) => tbl.id.equals(exchangeId))).getSingle();
  }

  /// Records clinical symptoms (e.g. for non-dialysis CKD or urological/catheter care).
  Future<DialysisSession> recordSymptomLog({
    String? id,
    required String patientId,
    required List<String> symptoms,
    String? notes,
    DateTime? recordedAt,
    String sessionType = 'symptom_log',
  }) async {
    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }

    if (symptoms.isEmpty && (notes == null || notes.trim().isEmpty)) {
      throw ArgumentError('Must provide at least one symptom or note.');
    }

    final logId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final logTime = recordedAt?.toUtc() ?? now;

    final sessionCompanion = DialysisSessionsCompanion.insert(
      id: drift.Value(logId),
      patientId: patientId,
      sessionType: sessionType,
      startedAt: logTime,
      endedAt: drift.Value(logTime),
      symptoms: drift.Value(symptoms.isNotEmpty ? symptoms.join(', ') : null),
      notes: drift.Value(notes),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.dialysisSessions).insert(sessionCompanion);
    return (_db.select(_db.dialysisSessions)..where((tbl) => tbl.id.equals(logId))).getSingle();
  }

  /// Deletes a dialysis session or exchange by ID.
  Future<int> deleteDialysisSession(String id) async {
    return (_db.delete(_db.dialysisSessions)..where((tbl) => tbl.id.equals(id))).go();
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

  /// Cancels an in-progress dialysis session with an optional cancellation reason.
  Future<DialysisSession> cancelDialysisSession(String sessionId, {String? reason}) async {
    final session = await (_db.select(_db.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).getSingleOrNull();
    if (session == null) {
      throw ArgumentError('Dialysis session not found with id: $sessionId');
    }

    final now = DateTime.now().toUtc();
    final combinedNotes = [
      if (session.notes != null && session.notes!.isNotEmpty) session.notes!,
      if (reason != null && reason.isNotEmpty) 'Cancelled: $reason',
    ].join(' | ');

    final updateCompanion = DialysisSessionsCompanion(
      status: const drift.Value('cancelled'),
      endedAt: drift.Value(now),
      notes: combinedNotes.isNotEmpty ? drift.Value(combinedNotes) : const drift.Value.absent(),
      updatedAt: drift.Value(now),
    );

    await (_db.update(_db.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).write(updateCompanion);
    return (_db.select(_db.dialysisSessions)..where((tbl) => tbl.id.equals(sessionId))).getSingle();
  }

  /// Queries the active (inProgress) hemodialysis session for a patient, if any.
  Future<DialysisSession?> getActiveSession(String patientId) async {
    return (_db.select(_db.dialysisSessions)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.status.equals('inProgress'))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Observes the active (inProgress) hemodialysis session for a patient reactively.
  Stream<DialysisSession?> watchActiveSession(String patientId) {
    return (_db.select(_db.dialysisSessions)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.status.equals('inProgress'))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.startedAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Records a standalone vascular or catheter exit-site access inspection in Drift SQLite.
  Future<AccessInspection> recordAccessInspection({
    String? id,
    required String patientId,
    String? accessType,
    String? anatomicalLocation,
    bool? thrillPresent,
    bool? bruitPresent,
    bool? rednessPresent,
    bool? swellingPresent,
    bool? dischargePresent,
    bool? painPresent,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }

    final inspectionId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final timestamp = recordedAt?.toUtc() ?? now;
    final effectiveAccessType = accessType ?? patient.vascularAccessType ?? 'none';
    final effectiveLocation = anatomicalLocation ?? patient.fistulaArmLocation ?? 'unknown';

    final companion = AccessInspectionsCompanion.insert(
      id: drift.Value(inspectionId),
      patientId: patientId,
      accessType: effectiveAccessType,
      anatomicalLocation: effectiveLocation,
      thrillPresent: drift.Value(thrillPresent),
      bruitPresent: drift.Value(bruitPresent),
      rednessPresent: drift.Value(rednessPresent),
      swellingPresent: drift.Value(swellingPresent),
      dischargePresent: drift.Value(dischargePresent),
      painPresent: drift.Value(painPresent),
      notes: drift.Value(notes),
      recordedAt: timestamp,
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.accessInspections).insert(companion);
    return (_db.select(_db.accessInspections)..where((tbl) => tbl.id.equals(inspectionId))).getSingle();
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

/// Stream provider for the currently active (inProgress) dialysis session of a patient.
final activeDialysisSessionStreamProvider = StreamProvider.family<DialysisSession?, String>((ref, patientId) {
  final repository = ref.watch(dialysisSessionRepositoryProvider);
  return repository.watchActiveSession(patientId);
});

