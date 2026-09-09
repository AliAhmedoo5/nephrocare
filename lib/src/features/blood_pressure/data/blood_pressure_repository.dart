import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/paired_bp_alarm_service.dart';
import '../domain/paired_bp_assessment.dart';
import '../domain/paired_bp_assessment_rules.dart';
import '../domain/vascular_safety_rules.dart';

/// Repository managing blood pressure logging, vascular safety enforcement,
/// paired anti-hypertensive hemodynamic assessment protocol, and reactive streams.
class BloodPressureRepository {
  final AppDatabase _db;
  final PairedBpAlarmService alarmService;
  final Uuid _uuid = const Uuid();

  BloodPressureRepository(this._db, [PairedBpAlarmService? alarmService])
      : alarmService = alarmService ?? PairedBpAlarmService();

  /// Records a blood pressure reading in Drift SQLite after verifying the Fistula Arm Safety Flag.
  /// Throws [FistulaArmSafetyException] if the measurement is attempted on a prohibited arm.
  Future<BloodPressureLog> recordBloodPressure({
    String? id,
    required String patientId,
    required int systolic,
    required int diastolic,
    required int pulse,
    required String armUsed,
    DateTime? recordedAt,
    bool isPairedAssessment = false,
    String? pairedRole,
    String? pairedAssessmentId,
    String? medicationAdministrationId,
    int? elapsedMinutes,
    int? systolicDelta,
    int? diastolicDelta,
    int? pulseDelta,
  }) async {
    // 1. Fetch patient profile to check vascular access configuration
    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }

    final isSafe = VascularSafetyRules.isArmSafe(patient: patient, arm: armUsed);
    if (!isSafe) {
      final prohibited = VascularSafetyRules.getProhibitedArm(patient);
      throw FistulaArmSafetyException(
        'Blood pressure measurement prohibited on $prohibited bearing vascular access. Hard lockout enforced.',
      );
    }

    final bpId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final timestamp = recordedAt?.toUtc() ?? now;

    final companion = BloodPressureLogsCompanion.insert(
      id: drift.Value(bpId),
      patientId: patientId,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      armUsed: armUsed,
      isSafeArm: const drift.Value(true),
      recordedAt: timestamp,
      isPairedAssessment: drift.Value(isPairedAssessment),
      pairedRole: drift.Value(pairedRole),
      pairedAssessmentId: drift.Value(pairedAssessmentId),
      medicationAdministrationId: drift.Value(medicationAdministrationId),
      elapsedMinutes: drift.Value(elapsedMinutes),
      systolicDelta: drift.Value(systolicDelta),
      diastolicDelta: drift.Value(diastolicDelta),
      pulseDelta: drift.Value(pulseDelta),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.bloodPressureLogs).insert(companion);
    return (_db.select(_db.bloodPressureLogs)..where((tbl) => tbl.id.equals(bpId))).getSingle();
  }

  /// Records a baseline blood pressure measurement immediately upon administering an anti-hypertensive medication.
  ///
  /// Enforces the Fistula Arm Safety Flag lockout and automatically schedules a local mobile
  /// background alarm/notification for the configured pharmacological onset window (default 30 min).
  Future<BloodPressureLog> recordBaselineBloodPressure({
    String? id,
    required String patientId,
    required String medicationAdministrationId,
    required String medicationName,
    required int systolic,
    required int diastolic,
    required int pulse,
    required String armUsed,
    String? pairedAssessmentId,
    int onsetWindowMinutes = PairedBpAssessmentRules.defaultOnsetWindowMinutes,
    DateTime? recordedAt,
  }) async {
    final pairId = pairedAssessmentId ?? _uuid.v4();
    final clampedInterval = PairedBpAssessmentRules.clampOnsetWindow(onsetWindowMinutes);
    final timestamp = recordedAt?.toUtc() ?? DateTime.now().toUtc();

    final baselineLog = await recordBloodPressure(
      id: id,
      patientId: patientId,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      armUsed: armUsed,
      recordedAt: timestamp,
      isPairedAssessment: true,
      pairedRole: PairedAssessmentRole.baseline,
      pairedAssessmentId: pairId,
      medicationAdministrationId: medicationAdministrationId,
    );

    // Schedule local mobile background alarm for 20-35 min window
    final scheduledTime = timestamp.add(Duration(minutes: clampedInterval));
    await alarmService.scheduleAlarm(
      pairedAssessmentId: pairId,
      patientId: patientId,
      medicationAdministrationId: medicationAdministrationId,
      medicationName: medicationName,
      scheduledFor: scheduledTime,
      intervalMinutes: clampedInterval,
      baselineSystolic: systolic,
      baselineDiastolic: diastolic,
      baselinePulse: pulse,
      safeArm: armUsed,
    );

    return baselineLog;
  }

  /// Records the follow-up blood pressure measurement after the pharmacological onset window.
  ///
  /// Calculates exact elapsed minutes and hemodynamic deltas (`systolicDelta`, `diastolicDelta`, `pulseDelta`)
  /// relative to the baseline reading, and clears the pending alarm.
  Future<BloodPressureLog> recordFollowUpBloodPressure({
    String? id,
    required String patientId,
    required String pairedAssessmentId,
    required int systolic,
    required int diastolic,
    required int pulse,
    required String armUsed,
    DateTime? recordedAt,
  }) async {
    final baseline = await (_db.select(_db.bloodPressureLogs)
          ..where((tbl) =>
              tbl.patientId.equals(patientId) &
              tbl.pairedAssessmentId.equals(pairedAssessmentId) &
              tbl.pairedRole.equals(PairedAssessmentRole.baseline)))
        .getSingleOrNull();

    if (baseline == null) {
      throw ArgumentError('Baseline blood pressure record not found for assessment ID: $pairedAssessmentId');
    }

    final timestamp = recordedAt?.toUtc() ?? DateTime.now().toUtc();
    final elapsedMinutes = PairedBpAssessmentRules.calculateElapsedMinutes(
      baselineTime: baseline.recordedAt,
      followUpTime: timestamp,
    );

    final deltas = PairedBpAssessmentRules.calculateDeltas(
      baselineSystolic: baseline.systolic,
      baselineDiastolic: baseline.diastolic,
      baselinePulse: baseline.pulse,
      followUpSystolic: systolic,
      followUpDiastolic: diastolic,
      followUpPulse: pulse,
    );

    final followUpLog = await recordBloodPressure(
      id: id,
      patientId: patientId,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      armUsed: armUsed,
      recordedAt: timestamp,
      isPairedAssessment: true,
      pairedRole: PairedAssessmentRole.followUp,
      pairedAssessmentId: pairedAssessmentId,
      medicationAdministrationId: baseline.medicationAdministrationId,
      elapsedMinutes: elapsedMinutes,
      systolicDelta: deltas.systolicDelta,
      diastolicDelta: deltas.diastolicDelta,
      pulseDelta: deltas.pulseDelta,
    );

    // Cancel / dismiss pending background alarm
    await alarmService.cancelAlarm(pairedAssessmentId);

    return followUpLog;
  }

  /// Filters an unfiltered list of paired blood pressure logs to those representing pending follow-ups.
  List<BloodPressureLog> _filterPendingFollowUps(List<BloodPressureLog> allPaired) {
    final followUpAssessmentIds = allPaired
        .where((log) => log.pairedRole == PairedAssessmentRole.followUp && log.pairedAssessmentId != null)
        .map((log) => log.pairedAssessmentId!)
        .toSet();

    return allPaired
        .where((log) =>
            log.pairedRole == PairedAssessmentRole.baseline &&
            log.pairedAssessmentId != null &&
            !followUpAssessmentIds.contains(log.pairedAssessmentId))
        .toList();
  }

  /// Groups paired baseline and follow-up blood pressure logs into [PairedBpAssessment] models.
  List<PairedBpAssessment> _groupPairedAssessments(List<BloodPressureLog> logs) {
    return PairedBpAssessment.groupFromLogs(logs);
  }

  /// Queries all pending paired assessments (baselines that have not yet had a follow-up recorded).
  Future<List<BloodPressureLog>> getPendingFollowUpAssessments(String patientId) async {
    final allPaired = await (_db.select(_db.bloodPressureLogs)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.isPairedAssessment.equals(true))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]))
        .get();

    return _filterPendingFollowUps(allPaired);
  }

  /// Reactive stream of pending follow-up assessments.
  Stream<List<BloodPressureLog>> watchPendingFollowUpAssessments(String patientId) {
    return (_db.select(_db.bloodPressureLogs)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.isPairedAssessment.equals(true))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]))
        .watch()
        .map(_filterPendingFollowUps);
  }

  /// Queries paired anti-hypertensive blood pressure assessments for a patient.
  Future<List<PairedBpAssessment>> getPairedAssessments(String patientId) async {
    final logs = await (_db.select(_db.bloodPressureLogs)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.isPairedAssessment.equals(true))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]))
        .get();

    return _groupPairedAssessments(logs);
  }

  /// Reactive stream of paired anti-hypertensive blood pressure assessments.
  Stream<List<PairedBpAssessment>> watchPairedAssessments(String patientId) {
    return (_db.select(_db.bloodPressureLogs)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.isPairedAssessment.equals(true))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]))
        .watch()
        .map(_groupPairedAssessments);
  }

  /// Queries the paired assessment linked to a specific medication administration.
  Future<PairedBpAssessment?> getPairedAssessmentForAdministration(String medicationAdministrationId) async {
    final logs = await (_db.select(_db.bloodPressureLogs)
          ..where((tbl) => tbl.medicationAdministrationId.equals(medicationAdministrationId)))
        .get();

    if (logs.isEmpty) return null;

    final baseline = logs.where((l) => l.pairedRole == 'baseline').firstOrNull ?? logs.first;
    final followUp = logs.where((l) => l.pairedRole == 'followUp').firstOrNull;

    return PairedBpAssessment(
      baseline: baseline,
      followUp: followUp,
      medicationAdministrationId: medicationAdministrationId,
    );
  }

  /// Observes blood pressure logs for a patient reactively, ordered most recent first.
  Stream<List<BloodPressureLog>> watchBloodPressureLogs(String patientId) {
    return (_db.select(_db.bloodPressureLogs)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]))
        .watch();
  }

  /// Retrieves blood pressure logs for a patient, ordered most recent first.
  Future<List<BloodPressureLog>> getBloodPressureLogs(String patientId) async {
    return (_db.select(_db.bloodPressureLogs)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]))
        .get();
  }

  /// Alias for [getBloodPressureLogs] to preserve historical hemodynamic trends terminology.
  Future<List<BloodPressureLog>> getHemodynamicTrends(String patientId) => getBloodPressureLogs(patientId);
}

/// Provider for [BloodPressureRepository].
final bloodPressureRepositoryProvider = Provider<BloodPressureRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final alarmService = ref.watch(pairedBpAlarmServiceProvider);
  return BloodPressureRepository(db, alarmService);
});

/// Stream provider for blood pressure logs of a specific patient.
final bloodPressureLogsStreamProvider = StreamProvider.family<List<BloodPressureLog>, String>((ref, patientId) {
  final repository = ref.watch(bloodPressureRepositoryProvider);
  return repository.watchBloodPressureLogs(patientId);
});

/// Stream provider for pending follow-up assessments for a specific patient.
final pendingFollowUpAssessmentsStreamProvider =
    StreamProvider.family<List<BloodPressureLog>, String>((ref, patientId) {
  final repository = ref.watch(bloodPressureRepositoryProvider);
  return repository.watchPendingFollowUpAssessments(patientId);
});

/// Stream provider for paired BP assessments for a specific patient.
final pairedBpAssessmentsStreamProvider =
    StreamProvider.family<List<PairedBpAssessment>, String>((ref, patientId) {
  final repository = ref.watch(bloodPressureRepositoryProvider);
  return repository.watchPairedAssessments(patientId);
});
