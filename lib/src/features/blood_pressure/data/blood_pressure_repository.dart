import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/vascular_safety_rules.dart';

/// Repository managing blood pressure logging, vascular safety enforcement,
/// and reactive stream subscriptions for hemodynamic trends.
class BloodPressureRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  BloodPressureRepository(this._db);

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
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.bloodPressureLogs).insert(companion);
    return (_db.select(_db.bloodPressureLogs)..where((tbl) => tbl.id.equals(bpId))).getSingle();
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
  return BloodPressureRepository(db);
});

/// Stream provider for blood pressure logs of a specific patient.
final bloodPressureLogsStreamProvider = StreamProvider.family<List<BloodPressureLog>, String>((ref, patientId) {
  final repository = ref.watch(bloodPressureRepositoryProvider);
  return repository.watchBloodPressureLogs(patientId);
});
