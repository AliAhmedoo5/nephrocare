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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final patientId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final created = createdAt?.toUtc() ?? now;
    final updated = updatedAt?.toUtc() ?? created;

    final companion = PatientsCompanion.insert(
      id: drift.Value(patientId),
      name: name.trim(),
      diagnosis: diagnosis,
      prescribedDryWeightKg: drift.Value(prescribedDryWeightKg),
      dailyFluidAllowanceMl: drift.Value(dailyFluidAllowanceMl),
      vascularAccessType: drift.Value(vascularAccessType),
      fistulaArmLocation: drift.Value(fistulaArmLocation),
      isCaregiverMirror: drift.Value(isCaregiverMirror),
      createdAt: drift.Value(created),
      updatedAt: drift.Value(updated),
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
          ..orderBy([
            (t) => drift.OrderingTerm.desc(t.updatedAt),
            (t) => drift.OrderingTerm.desc(t.createdAt),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Retrieves the currently active patient profile once.
  Future<Patient?> getActivePatient() async {
    return (_db.select(_db.patients)
          ..orderBy([
            (t) => drift.OrderingTerm.desc(t.updatedAt),
            (t) => drift.OrderingTerm.desc(t.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Retrieves a specific patient profile by ID.
  Future<Patient?> getPatientById(String id) async {
    return (_db.select(_db.patients)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Observes a specific patient profile by ID reactively.
  Stream<Patient?> watchPatientById(String id) {
    return (_db.select(_db.patients)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// Retrieves all patient profiles, ordered by most recently updated first.
  Future<List<Patient>> getAllPatients() async {
    return (_db.select(_db.patients)..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)])).get();
  }

  /// Observes all patient profiles reactively, ordered by most recently updated first.
  Stream<List<Patient>> watchAllPatients() {
    return (_db.select(_db.patients)..orderBy([(t) => drift.OrderingTerm.desc(t.updatedAt)])).watch();
  }

  /// Sets the active patient profile by updating its `updatedAt` timestamp to now.
  /// This causes the active patient queries/streams to emit this patient,
  /// persisting the active profile selection across app restarts.
  Future<void> setActivePatient(String patientId, {DateTime? asOf}) async {
    final now = asOf?.toUtc() ?? DateTime.now().toUtc();
    await (_db.update(_db.patients)..where((tbl) => tbl.id.equals(patientId))).write(
      PatientsCompanion(
        updatedAt: drift.Value(now),
      ),
    );
  }
}

/// Provider for [PatientRepository].
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PatientRepository(db);
});

/// State provider allowing explicit override/selection of the active patient ID in memory.
final activePatientIdProvider = StateProvider<String?>((ref) => null);

/// Reactive stream provider for the active patient profile.
/// If an explicit active patient ID is selected in [activePatientIdProvider],
/// it watches that patient. Otherwise, it observes the most recently active patient.
final activePatientStreamProvider = StreamProvider<Patient?>((ref) {
  final repository = ref.watch(patientRepositoryProvider);
  final activeId = ref.watch(activePatientIdProvider);
  if (activeId != null) {
    return repository.watchPatientById(activeId);
  }
  return repository.watchActivePatient();
});

/// Reactive stream provider for all patient profiles on the device.
final allPatientsStreamProvider = StreamProvider<List<Patient>>((ref) {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.watchAllPatients();
});
