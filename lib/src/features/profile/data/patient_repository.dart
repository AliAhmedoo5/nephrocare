import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Repository managing patient profile CRUD operations and reactive stream subscriptions.
class PatientRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  PatientRepository(this._db);

  /// Creates a new patient profile record persisted in local Drift SQLite.
  Future<Patient> createPatientProfile({
    String? id,
    required String name,
    required String diagnosis,
    double? prescribedDryWeightKg,
    int? dailyFluidAllowanceMl,
    String? vascularAccessType,
    String? fistulaArmLocation,
    bool isCaregiverMirror = false,
  }) async {
    final patientId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();

    final companion = PatientsCompanion.insert(
      id: drift.Value(patientId),
      name: name.trim(),
      diagnosis: diagnosis,
      prescribedDryWeightKg: drift.Value(prescribedDryWeightKg),
      dailyFluidAllowanceMl: drift.Value(dailyFluidAllowanceMl),
      vascularAccessType: drift.Value(vascularAccessType),
      fistulaArmLocation: drift.Value(fistulaArmLocation),
      isCaregiverMirror: drift.Value(isCaregiverMirror),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.patients).insert(companion);
    return (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingle();
  }

  /// Updates an existing patient profile and stamps `updated_at`.
  Future<Patient> updatePatientProfile({
    required String id,
    required String name,
    required String diagnosis,
    double? prescribedDryWeightKg,
    int? dailyFluidAllowanceMl,
    String? vascularAccessType,
    String? fistulaArmLocation,
    bool isCaregiverMirror = false,
  }) async {
    final now = DateTime.now().toUtc();

    final companion = PatientsCompanion(
      name: drift.Value(name.trim()),
      diagnosis: drift.Value(diagnosis),
      prescribedDryWeightKg: drift.Value(prescribedDryWeightKg),
      dailyFluidAllowanceMl: drift.Value(dailyFluidAllowanceMl),
      vascularAccessType: drift.Value(vascularAccessType),
      fistulaArmLocation: drift.Value(fistulaArmLocation),
      isCaregiverMirror: drift.Value(isCaregiverMirror),
      updatedAt: drift.Value(now),
    );

    await (_db.update(_db.patients)..where((tbl) => tbl.id.equals(id))).write(companion);
    return (_db.select(_db.patients)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  /// Observes the currently active patient profile reactively.
  /// Selects the most recently updated patient profile or returns null if no profiles exist.
  Stream<Patient?> watchActivePatient() {
    return (_db.select(_db.patients)
          ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Retrieves the currently active patient profile once.
  Future<Patient?> getActivePatient() async {
    return (_db.select(_db.patients)
          ..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}

/// Provider for [PatientRepository].
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PatientRepository(db);
});

/// Reactive stream provider for the active patient profile.
final activePatientStreamProvider = StreamProvider<Patient?>((ref) {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.watchActivePatient();
});
