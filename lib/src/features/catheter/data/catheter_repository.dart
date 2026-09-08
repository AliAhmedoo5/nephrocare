import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/catheter_lifespan_rules.dart';

/// Repository managing Urine Foley Catheter lifecycle persistence in Drift SQLite,
/// 14-day lifespan tracking, and reactive stream subscriptions.
class CatheterRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  CatheterRepository(this._db);

  /// Ensures that the patient profile exists or throws [ArgumentError].
  Future<Patient> _ensurePatientExists(String patientId) async {
    final patient = await (_db.select(_db.patients)..where((tbl) => tbl.id.equals(patientId))).getSingleOrNull();
    if (patient == null) {
      throw ArgumentError('Patient not found with id: $patientId');
    }
    return patient;
  }

  /// Records an indwelling Urine Foley Catheter insertion event.
  ///
  /// Automatically sets the 14-day replacement due date, sets status to 'active',
  /// and marks any previous active catheter as 'replaced'.
  Future<CatheterEvent> recordCatheterInsertion({
    String? id,
    required String patientId,
    required DateTime insertionDate,
    String? notes,
    String catheterType = 'foley',
  }) async {
    await _ensurePatientExists(patientId);

    final now = DateTime.now().toUtc();
    final insertUtc = insertionDate.toUtc();
    final dueDateUtc = insertUtc.add(const Duration(days: CatheterLifespanRules.lifespanDays));
    final catheterId = id ?? _uuid.v4();

    // Mark any existing active catheter for this patient as 'replaced'
    await (_db.update(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.status.equals('active')))
        .write(
      CatheterEventsCompanion(
        status: const drift.Value('replaced'),
        updatedAt: drift.Value(now),
      ),
    );

    final companion = CatheterEventsCompanion.insert(
      id: drift.Value(catheterId),
      patientId: patientId,
      catheterType: catheterType,
      insertionDate: insertUtc,
      replacementDueDate: dueDateUtc,
      status: 'active',
      notes: drift.Value(notes),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.catheterEvents).insert(companion);
    return (_db.select(_db.catheterEvents)..where((tbl) => tbl.id.equals(catheterId))).getSingle();
  }

  /// Records a catheter replacement event, retiring active catheter and starting a new 14-day cycle.
  Future<CatheterEvent> recordCatheterReplacement({
    String? id,
    required String patientId,
    required DateTime replacementDate,
    String? notes,
    String catheterType = 'foley',
  }) async {
    return recordCatheterInsertion(
      id: id,
      patientId: patientId,
      insertionDate: replacementDate,
      notes: notes,
      catheterType: catheterType,
    );
  }

  /// Queries the currently active catheter for a patient.
  Future<CatheterEvent?> getActiveCatheter(String patientId) async {
    return (_db.select(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.status.equals('active'))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.insertionDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Observes the active catheter for a patient reactively.
  Stream<CatheterEvent?> watchActiveCatheter(String patientId) {
    return (_db.select(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.status.equals('active'))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.insertionDate)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Queries all catheter events for a patient ordered most recent first.
  Future<List<CatheterEvent>> getCatheterHistory(String patientId) async {
    return (_db.select(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.insertionDate)]))
        .get();
  }

  /// Observes all catheter events for a patient reactively.
  Stream<List<CatheterEvent>> watchCatheterHistory(String patientId) {
    return (_db.select(_db.catheterEvents)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.insertionDate)]))
        .watch();
  }

  /// Evaluates the 14-day lifespan summary for a patient's active catheter.
  Future<CatheterLifespanSummary?> getCatheterLifespanSummary(
    String patientId, {
    DateTime? asOf,
  }) async {
    final active = await getActiveCatheter(patientId);
    if (active == null) return null;

    return CatheterLifespanRules.evaluateLifespan(
      insertionDate: active.insertionDate,
      replacementDueDate: active.replacementDueDate,
      asOf: asOf,
    );
  }

  /// Observes the 14-day lifespan summary for a patient's active catheter reactively.
  Stream<CatheterLifespanSummary?> watchCatheterLifespanSummary(
    String patientId, {
    DateTime? asOf,
  }) {
    return watchActiveCatheter(patientId).map((active) {
      if (active == null) return null;
      return CatheterLifespanRules.evaluateLifespan(
        insertionDate: active.insertionDate,
        replacementDueDate: active.replacementDueDate,
        asOf: asOf,
      );
    });
  }
}

/// Provider for [CatheterRepository].
final catheterRepositoryProvider = Provider<CatheterRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CatheterRepository(db);
});

/// Stream provider for the active catheter of a patient.
final activeCatheterStreamProvider = StreamProvider.family<CatheterEvent?, String>((ref, patientId) {
  final repository = ref.watch(catheterRepositoryProvider);
  return repository.watchActiveCatheter(patientId);
});

/// Stream provider for the catheter events history of a patient.
final catheterHistoryStreamProvider = StreamProvider.family<List<CatheterEvent>, String>((ref, patientId) {
  final repository = ref.watch(catheterRepositoryProvider);
  return repository.watchCatheterHistory(patientId);
});

/// Stream provider for the 14-day catheter lifespan summary of a patient.
final catheterLifespanSummaryStreamProvider =
    StreamProvider.family<CatheterLifespanSummary?, String>((ref, patientId) {
  final repository = ref.watch(catheterRepositoryProvider);
  return repository.watchCatheterLifespanSummary(patientId);
});
