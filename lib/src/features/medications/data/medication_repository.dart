import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Repository managing prescribed Medication Regimens and 1-tap Administrations.
class MedicationRepository {
  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  MedicationRepository(this._database);

  /// Prescribes a new medication regimen for a patient with clinical classifications.
  Future<Medication> createMedication({
    String? id,
    required String patientId,
    required String name,
    required String dosage,
    required String frequency,
    String? instructions,
    bool isPhosphateBinder = false,
    bool isAntiHypertensive = false,
    bool isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final patient = await (_database.select(_database.patients)
          ..where((tbl) => tbl.id.equals(patientId)))
        .getSingleOrNull();

    if (patient == null) {
      throw ArgumentError('Cannot prescribe medication for nonexistent patient ID: $patientId');
    }

    final medId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final created = createdAt?.toUtc() ?? now;
    final updated = updatedAt?.toUtc() ?? created;

    final companion = MedicationsCompanion.insert(
      id: Value(medId),
      patientId: patientId,
      name: name.trim(),
      dosage: dosage.trim(),
      frequency: frequency.trim(),
      instructions: Value(instructions?.trim()),
      isPhosphateBinder: Value(isPhosphateBinder),
      isAntiHypertensive: Value(isAntiHypertensive),
      isActive: Value(isActive),
      createdAt: Value(created),
      updatedAt: Value(updated),
    );

    await _database.into(_database.medications).insert(companion);
    return (_database.select(_database.medications)
          ..where((tbl) => tbl.id.equals(medId)))
        .getSingle();
  }

  /// Updates prescribed medication details and active status.
  Future<Medication> updateMedication({
    required String id,
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
    bool? isPhosphateBinder,
    bool? isAntiHypertensive,
    bool? isActive,
    DateTime? updatedAt,
  }) async {
    final existing = await getMedicationById(id);
    if (existing == null) {
      throw ArgumentError('Medication with ID $id does not exist');
    }

    final updated = updatedAt?.toUtc() ?? DateTime.now().toUtc();
    final companion = MedicationsCompanion(
      id: Value(id),
      patientId: Value(existing.patientId),
      name: name != null ? Value(name.trim()) : Value(existing.name),
      dosage: dosage != null ? Value(dosage.trim()) : Value(existing.dosage),
      frequency: frequency != null ? Value(frequency.trim()) : Value(existing.frequency),
      instructions: instructions != null ? Value(instructions.trim()) : Value(existing.instructions),
      isPhosphateBinder: isPhosphateBinder != null ? Value(isPhosphateBinder) : Value(existing.isPhosphateBinder),
      isAntiHypertensive: isAntiHypertensive != null ? Value(isAntiHypertensive) : Value(existing.isAntiHypertensive),
      isActive: isActive != null ? Value(isActive) : Value(existing.isActive),
      updatedAt: Value(updated),
    );

    await (_database.update(_database.medications)
          ..where((tbl) => tbl.id.equals(id)))
        .write(companion);

    return (_database.select(_database.medications)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  /// Queries a single medication by ID.
  Future<Medication?> getMedicationById(String id) {
    return (_database.select(_database.medications)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Queries active prescribed medications for a patient, ordered by name.
  Future<List<Medication>> getActiveMedications(String patientId) {
    return (_database.select(_database.medications)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.isActive.equals(true))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)]))
        .get();
  }

  /// Reactive stream of active prescribed medications.
  Stream<List<Medication>> watchActiveMedications(String patientId) {
    return (_database.select(_database.medications)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.isActive.equals(true))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)]))
        .watch();
  }

  /// Queries all prescribed medications (active and inactive) for a patient.
  Future<List<Medication>> getAllMedications(String patientId) {
    return (_database.select(_database.medications)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Reactive stream of all medications.
  Stream<List<Medication>> watchAllMedications(String patientId) {
    return (_database.select(_database.medications)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  /// Checks if the patient has any active Phosphate Binder prescriptions.
  Future<bool> hasActivePhosphateBinders(String patientId) async {
    final countQuery = _database.selectOnly(_database.medications)
      ..addColumns([_database.medications.id.count()])
      ..where(_database.medications.patientId.equals(patientId) &
          _database.medications.isActive.equals(true) &
          _database.medications.isPhosphateBinder.equals(true));

    final count = await countQuery.map((row) => row.read(_database.medications.id.count())).getSingle();
    return (count ?? 0) > 0;
  }

  /// Queries active Phosphate Binders prescribed to the patient.
  Future<List<Medication>> getActivePhosphateBinders(String patientId) {
    return (_database.select(_database.medications)
          ..where((tbl) =>
              tbl.patientId.equals(patientId) &
              tbl.isActive.equals(true) &
              tbl.isPhosphateBinder.equals(true))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)]))
        .get();
  }

  /// Reactive stream of active Phosphate Binders.
  Stream<List<Medication>> watchActivePhosphateBinders(String patientId) {
    return (_database.select(_database.medications)
          ..where((tbl) =>
              tbl.patientId.equals(patientId) &
              tbl.isActive.equals(true) &
              tbl.isPhosphateBinder.equals(true))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)]))
        .watch();
  }

  /// Records a 1-tap medication administration.
  ///
  /// Pulls the default dosage, clinical classifications, and metadata from the prescribed
  /// medication, recording the timestamp at `DateTime.now().toUtc()` if not specified.
  Future<MedicationAdministration> recordAdministration({
    String? id,
    required String patientId,
    required String medicationId,
    DateTime? administeredAt,
    String? dosage,
    String? medicationName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final med = await getMedicationById(medicationId);
    if (med == null) {
      throw ArgumentError('Cannot record administration for nonexistent medication ID: $medicationId');
    }

    final adminId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    final adminTime = administeredAt?.toUtc() ?? now;
    final created = createdAt?.toUtc() ?? now;
    final updated = updatedAt?.toUtc() ?? created;

    final companion = MedicationAdministrationsCompanion.insert(
      id: Value(adminId),
      patientId: patientId,
      medicationId: medicationId,
      medicationName: medicationName?.trim() ?? med.name,
      dosage: dosage?.trim() ?? med.dosage,
      administeredAt: adminTime,
      notes: Value(notes?.trim()),
      isPhosphateBinder: Value(med.isPhosphateBinder),
      isAntiHypertensive: Value(med.isAntiHypertensive),
      createdAt: Value(created),
      updatedAt: Value(updated),
    );

    await _database.into(_database.medicationAdministrations).insert(companion);
    return (_database.select(_database.medicationAdministrations)
          ..where((tbl) => tbl.id.equals(adminId)))
        .getSingle();
  }

  /// Updates an existing administration record (to correct accidental entries).
  Future<MedicationAdministration> updateAdministration({
    required String id,
    DateTime? administeredAt,
    String? dosage,
    String? notes,
    DateTime? updatedAt,
  }) async {
    final existing = await (_database.select(_database.medicationAdministrations)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();

    if (existing == null) {
      throw ArgumentError('Medication administration with ID $id does not exist');
    }

    final updated = updatedAt?.toUtc() ?? DateTime.now().toUtc();
    final companion = MedicationAdministrationsCompanion(
      id: Value(id),
      patientId: Value(existing.patientId),
      medicationId: Value(existing.medicationId),
      medicationName: Value(existing.medicationName),
      dosage: dosage != null ? Value(dosage.trim()) : Value(existing.dosage),
      administeredAt: administeredAt != null ? Value(administeredAt.toUtc()) : Value(existing.administeredAt),
      notes: notes != null ? Value(notes.trim()) : Value(existing.notes),
      isPhosphateBinder: Value(existing.isPhosphateBinder),
      isAntiHypertensive: Value(existing.isAntiHypertensive),
      updatedAt: Value(updated),
    );

    await (_database.update(_database.medicationAdministrations)
          ..where((tbl) => tbl.id.equals(id)))
        .write(companion);

    return (_database.select(_database.medicationAdministrations)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  /// Deletes a medication administration record (to correct accidental entries).
  Future<int> deleteAdministration(String id) {
    return (_database.delete(_database.medicationAdministrations)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// Queries administrations for a patient, optionally filtering since a given timestamp.
  Future<List<MedicationAdministration>> getAdministrations(
    String patientId, {
    DateTime? since,
  }) {
    var query = _database.select(_database.medicationAdministrations)
      ..where((tbl) => tbl.patientId.equals(patientId));

    if (since != null) {
      query = query..where((tbl) => tbl.administeredAt.isBiggerOrEqualValue(since.toUtc()));
    }

    return (query..orderBy([(tbl) => OrderingTerm(expression: tbl.administeredAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Reactive stream of administrations for a patient.
  Stream<List<MedicationAdministration>> watchAdministrations(
    String patientId, {
    DateTime? since,
  }) {
    var query = _database.select(_database.medicationAdministrations)
      ..where((tbl) => tbl.patientId.equals(patientId));

    if (since != null) {
      query = query..where((tbl) => tbl.administeredAt.isBiggerOrEqualValue(since.toUtc()));
    }

    return (query..orderBy([(tbl) => OrderingTerm(expression: tbl.administeredAt, mode: OrderingMode.desc)]))
        .watch();
  }

  /// Queries administrations for today.
  Future<List<MedicationAdministration>> getTodayAdministrations(
    String patientId, {
    DateTime? asOf,
  }) {
    final ref = asOf?.toUtc() ?? DateTime.now().toUtc();
    final startOfDay = DateTime.utc(ref.year, ref.month, ref.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (_database.select(_database.medicationAdministrations)
          ..where((tbl) =>
              tbl.patientId.equals(patientId) &
              tbl.administeredAt.isBiggerOrEqualValue(startOfDay) &
              tbl.administeredAt.isSmallerThanValue(endOfDay))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.administeredAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Reactive stream of today's administrations.
  Stream<List<MedicationAdministration>> watchTodayAdministrations(
    String patientId, {
    DateTime? asOf,
  }) {
    final ref = asOf?.toUtc() ?? DateTime.now().toUtc();
    final startOfDay = DateTime.utc(ref.year, ref.month, ref.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (_database.select(_database.medicationAdministrations)
          ..where((tbl) =>
              tbl.patientId.equals(patientId) &
              tbl.administeredAt.isBiggerOrEqualValue(startOfDay) &
              tbl.administeredAt.isSmallerThanValue(endOfDay))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.administeredAt, mode: OrderingMode.desc)]))
        .watch();
  }
}

/// Riverpod provider for [MedicationRepository].
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return MedicationRepository(database);
});

/// Reactive stream of active prescribed medications for a patient.
final activeMedicationsStreamProvider =
    StreamProvider.family<List<Medication>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).watchActiveMedications(patientId);
});

/// Reactive stream of all prescribed medications for a patient.
final allMedicationsStreamProvider =
    StreamProvider.family<List<Medication>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).watchAllMedications(patientId);
});

/// Reactive stream of active Phosphate Binders for a patient.
final activePhosphateBindersStreamProvider =
    StreamProvider.family<List<Medication>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).watchActivePhosphateBinders(patientId);
});

/// Reactive stream of today's medication administrations for a patient.
final todayAdministrationsStreamProvider =
    StreamProvider.family<List<MedicationAdministration>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).watchTodayAdministrations(patientId);
});

/// Reactive stream of recent administrations for a patient.
final recentAdministrationsStreamProvider =
    StreamProvider.family<List<MedicationAdministration>, String>((ref, patientId) {
  return ref.watch(medicationRepositoryProvider).watchAdministrations(patientId);
});
